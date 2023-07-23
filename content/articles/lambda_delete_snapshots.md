---
author:
  name: "Jack Collins"
title: "Using AWS Lambda to automate EBS Image & Snapshot deletion"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-07-15T11:34:11+01:00
draft: true
toc: false
images:
tags:
  - aws
---

- [Scenario](#scenario)
- [Create an IAM Role](#iam)

---

## Scenario{#scenario}

**Amazon Machine Images** are a great way to back up your AWS EC2 instances, for example before patching.  
However, there is no easy way to delete the Images afterwards. Each AMI has underlying **Elastic Block Store** (EBS) Snapshots attached to it, often many, which to delete require you to deregister the AMI and then find each Snapshot to then remove, via the AWS GUI. This can be time consuming and frustrating, and almost impossible if you're taking AMIs of many servers, for example before a patch cycle of hundreds of servers.

Fortunately there's an easy way to automate the deregistering of specific AMIs, as well as the deletion of underlying, related Snapshots, via a Python Lambda function.

In this scenario, we're going to assume we've applied a tag to all of our Images, with the format *Key=Purpose* and *Value=Patching*, which is easy to do at the time of taking the AMI.  
It is possible to use other critera for filtering, such as the age of the AMI, the title, etc., simply amend the Python code below to suit your needs.

---

## Steps

### Create an IAM Role

1. bla

### Create a Lambda Function

1. Use the search bar within the AWS GUI to search for 'Lambda' and navigate to it
2. On the left menu, select 'Functions'
3. On the right side, click 'Create Function'
4. Select;
   1. Author from scratch
   2. Choose a Function name (in this scenario I'm going to use *ami-image-delete*)
   3. Select the Runtime as Python (in this scenario *Python 3.10*)
   4. Drop down 'Change default execution role', select 'Use an existing role' and then select the role we created earlier; *ami-image-role*
   5. Leave everything else as default and select 'Create function'
5. Enter the Lambda function code as below. I've included some annotation throughout;

```
# Script Purpose: Delete patching related AMIs via tag Purpose=Patching

import boto3

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    # Create empty Lists for later population
    deregistered_images = []
    deleted_snapshots = []

    # Filter out AMIs with the tag Purpose=Patching
    response = ec2_client.describe_images(Filters=[
      {'Name': 'tag-key', 'Values': ['Purpose']},
      {'Name': 'tag-value', 'Values': ['Patching']}
    ])

    if 'Images' in response:
      images = response['Images']

      # Add Image ID to List and Deregister AMIs
      for image in images:
        image_id = image['ImageId']
        deregistered_images.append(image_id)
        ec2_client.deregister_image(ImageId=imageid)

        # For each image, get underlying Snapshots, add them to List and delete them
        block_device_mappings = image.get('BlockDeviceMappings', [])
        for mapping in block_device_mappings:
          if 'Ebs' in mapping and 'SnapshotId' in mapping['Ebs']:
            snapshot_id = mapping['Ebs']['SnapshotId']
            deleted_snapshots.append(snapshot_id)
            ec2_client.delete_snapshot(SnapshotId=snapshot_id)

      output_message = "Deregistered AMIs: {} Deleted Snapshots: {}".format(deregistered_images, deleted_snapshots)

    else:
      output_message = "No AMIs found to delete."

    return {
      'statusCode': 200,
      'body': output_message
    }
```

6. Deploy the code
7. (Optional) Take some EC2 AMI Images of servers on your AWS account
8. Click Test on the Lambda Function. If it was successful, you should see an output like the following;



---

## []

[Top of page](#top)