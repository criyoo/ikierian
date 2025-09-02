# Approach, Assumptions, and Challenges

## 🎯 **Approach**
Based on project objectives, the project was implemented using a **modular Terraform architecture** with clear separation of concerns:
- **S3 Module**: Manages data storage with encryption, versioning, and lifecycle policies
- **IAM Module**: Handles security with least-privilege policies and role-based access. The permissions are restricted to the specific s3 buckets and services.
- **Lambda Module**: Implemented in Python with a simple JSON parsing and validation, it is triggered by an S3 event notification whenever a new file is uploaded to the Raw Data s3 Bucket.  
Function logic:
  - Read the incoming JSON file.
  - Extract required fields (patient_id, patient_name).
  - Write the new JSON object to the Processed Data Bucket with a similar or prefixed filename.
- **CloudWatch Logs**: Lambda automatically integrates with CloudWatch when proper permissions are set. This ensure structured logs with clear messages (e.g., when file is read, transformed, or written) are logged. Log retention policies was also configured in Terraform to manage costs.
- **Root Configuration**: Orchestrates the terraform modules and manages dependencies



## 📋 **Assumptions**
From the project objectives and deliverable requirement, the following assumption have been made.
- **Data Format**: The provided ikerian_sample.json data is consistently well-structured and formatted.
- **Processing Requirements**: requires a consistently simple field extraction (patient_id, patient_name). JSON files are small (a few patient record per file). For larger/multiple records, additional iteration logic may be required.
- **AWS Environment**: Full AWS access with appropriate permissions
- **S3 bucket**: names will be unique globally (use of bucket prefix in Terraform will handle naming conflicts with variables/prefixes).
- **Security Level**: Standard AWS security practices is sufficient
- **Use of Public Network**: No private networking is required, AWS lambda uses AWS-managed VPC by default and provides direct internet access for AWS service calls. The public access blocked s3 bucket permission should be sufficient
- **Scalability**: Lambda auto-scaling is designed to handles variable workloads, so no additional scaling is required
- **Data Volume**: Only moderate data processing will be required based on file size
- **Error Handling**: Lambda and cloudwatch integration provides for Graceful degradation with detailed logging
- **Monitoring**: From project objectives CloudWatch logs should provide sufficient observability
- **Compliance**: Basic data protection measures should be adequate (encryption, access control)
- **Maintenance**: Continued mainteance and infrastructure management would be possible with terraform.
- **Data Sensitivity**: Due to some sensitive inforamtion in data, data would require encryption
- **Processing Speed**: Near real-time processing should be acceptable
- **Cost Optimization**: From project objective and deliverable requirement, serverless architecture will provides cost efficiency



## 🚨 **Challenges Faced**
**Challenge**: Encountered s3 Bucket naming conflicts.  
**Solution**: Use of bucket prefix to eliminate the potential of naming conflict.

**Challenge**: Permissions Misconfiguration - lambda was not reading the raw data or writting to the processed bucket.  
 **Solution**: Needed to test the IAM policy permission to ensure Lambda has the exact S3 actions needed to interract with the raw and processed s3 bucket.

**Challenge**: s3 event trigger wasn't working  
**Solution**:  I missed configuring the s3 bucket notification, I needed to ensure S3 event notifications was correctly wired to Lambda using the `aws_s3_bucket_notification` resource and the correct permission granted.

**Challenge**: Module interdependencies was causing terraform to throw errors during plan phase  
**Solution**: The module implementation required careful ordering, I needed to use explicit `depends_on` and proper output variable passing between modules 

**Challenge**: Terraform was failing to read variable file while running plan.  
**Solution**: I needed to check and create the appropraite Terraform workspaces and updated the Make file to auto read the workspace and mirror the environment variables define in the .tfvars file

**Challenge**: Encountered conflicts with some resource naming  
**Solution**: I reviewed the resource naming and used consistent naming conventions across the project project and also use of environment prefixes


## 🚨 **Potential Future Challenges**
**File Format Issues** – If JSON structure changes, Lambda could fail to parse correctly.


## 🚀 **Outcome**

This project successfully delivers a **serverless data pipeline** that:
- ✅ **Processes JSON data reliably** with comprehensive validation
- ✅ **Scales automatically** using AWS Lambda
- ✅ **Maintains security** with encryption and list privilage access controls
- ✅ **Provides observability** through structured logging to cloudwatch
- ✅ **Automates infrastructure** by using Terraform best practices
- ✅ **Supports multiple environments** for development and any other environment

