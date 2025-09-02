import json
import boto3
import logging
from datetime import datetime
import os
from typing import Dict, List, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')

def validate_record(record: Dict[str, Any], record_index: int) -> Dict[str, Any]:
    """
    Validate a single record for required fields and data types.
    
    Args:
        record: The record to validate
        record_index: Index of the record for error reporting
        
    Returns:
        Dict containing validation result and processed record
        
    Raises:
        ValueError: If validation fails
    """
    validation_errors = []
    
    # Check if record is a dictionary
    if not isinstance(record, dict):
        raise ValueError(f"Record {record_index}: Must be a dictionary, got {type(record).__name__}")
    
    # Validate patient_id field
    if 'patient_id' not in record:
        validation_errors.append(f"Record {record_index}: Missing required field 'patient_id'")
    elif not isinstance(record['patient_id'], str):
        validation_errors.append(f"Record {record_index}: 'patient_id' must be a string, got {type(record['patient_id']).__name__}")
    elif not record['patient_id'].strip():
        validation_errors.append(f"Record {record_index}: 'patient_id' cannot be empty or whitespace")
    
    # Validate patient_name field
    if 'patient_name' not in record:
        validation_errors.append(f"Record {record_index}: Missing required field 'patient_name'")
    elif not isinstance(record['patient_name'], str):
        validation_errors.append(f"Record {record_index}: 'patient_name' must be a string, got {type(record['patient_name']).__name__}")
    elif not record['patient_name'].strip():
        validation_errors.append(f"Record {record_index}: 'patient_name' cannot be empty or whitespace")
    
    # Raise error if validation failed
    if validation_errors:
        raise ValueError("; ".join(validation_errors))
    
    # Return validated record with only required fields
    return {
        'patient_id': record['patient_id'].strip(),
        'patient_name': record['patient_name'].strip()
    }

def validate_data_structure(data: Any) -> List[Dict[str, Any]]:
    """
    Validate the overall data structure and return validated records.
    
    Args:
        data: The data to validate
        
    Returns:
        List of validated records
        
    Raises:
        ValueError: If data structure is invalid
    """
    # Check if data is a list
    if not isinstance(data, list):
        raise ValueError(f"Data must be a list, got {type(data).__name__}")
    
    # Check if list is not empty
    if not data:
        raise ValueError("Data list cannot be empty")
    
    validated_records = []
    validation_errors = []
    
    for i, record in enumerate(data):
        try:
            validated_record = validate_record(record, i)
            validated_records.append(validated_record)
        except ValueError as e:
            validation_errors.append(str(e))
    
    # If there are validation errors, raise them all together
    if validation_errors:
        raise ValueError("Data validation failed:\n" + "\n".join(validation_errors))
    
    return validated_records

def lambda_handler(event, context):
    """
    Lambda function to process JSON data from raw bucket and store processed data
    with comprehensive data validation.
    """
    try:
        # Get bucket names from environment variables
        raw_bucket = os.environ['RAW_DATA_BUCKET']
        processed_bucket = os.environ['PROCESSED_DATA_BUCKET']
        
        logger.info(f"Starting data processing from {raw_bucket} to {processed_bucket}")
        
        # Get the S3 object key from the event
        s3_key = event['Records'][0]['s3']['object']['key']
        logger.info(f"Processing file: {s3_key}")
        
        # Read JSON data from raw bucket
        response = s3_client.get_object(Bucket=raw_bucket, Key=s3_key)
        raw_data = json.loads(response['Body'].read().decode('utf-8'))
        
        logger.info(f"Successfully read {len(raw_data)} records from raw data")
        
        # Validate data structure and content
        logger.info("Starting data validation...")
        try:
            validated_data = validate_data_structure(raw_data)
            logger.info(f"Data validation successful: {len(validated_data)} records validated")
        except ValueError as validation_error:
            logger.error(f"Data validation failed: {str(validation_error)}")
            # Create error report
            error_report = {
                'error_type': 'validation_error',
                'error_message': str(validation_error),
                'file_processed': s3_key,
                'timestamp': datetime.now().isoformat(),
                'records_attempted': len(raw_data) if isinstance(raw_data, list) else 0
            }
            
            # Write error report to processed bucket
            error_key = f"error_reports/validation_error_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            s3_client.put_object(
                Bucket=processed_bucket,
                Key=error_key,
                Body=json.dumps(error_report, indent=2),
                ContentType='application/json'
            )
            
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Data validation failed',
                    'error': str(validation_error),
                    'error_report_file': error_key,
                    'input_records': len(raw_data) if isinstance(raw_data, list) else 0,
                    'validated_records': 0
                })
            }
        
        # Process validated data
        logger.info("Processing validated data...")
        processed_data = validated_data  # Already in correct format from validation
        
        logger.info(f"Successfully processed {len(processed_data)} records")
        
        # Generate output filename with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_key = f"processed_data_{timestamp}.json"
        
        # Write processed data to processed bucket
        s3_client.put_object(
            Bucket=processed_bucket,
            Key=output_key,
            Body=json.dumps(processed_data, indent=2),
            ContentType='application/json'
        )
        
        logger.info(f"Successfully wrote processed data to {processed_bucket}/{output_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data processing completed successfully',
                'input_records': len(raw_data),
                'validated_records': len(validated_data),
                'output_records': len(processed_data),
                'output_file': output_key,
                'validation_status': 'passed'
            })
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON parsing error: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({
                'message': 'Invalid JSON format',
                'error': str(e),
                'input_records': 0,
                'validated_records': 0
            })
        }
    except KeyError as e:
        logger.error(f"Missing required field in event: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({
                'message': 'Invalid event structure',
                'error': f"Missing field: {str(e)}",
                'input_records': 0,
                'validated_records': 0
            })
        }
    except Exception as e:
        logger.error(f"Unexpected error processing data: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Internal processing error',
                'error': str(e),
                'input_records': 0,
                'validated_records': 0
            })
        }
