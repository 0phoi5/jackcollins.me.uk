---
author:
  name: "Jack Collins"
title: "Using AWS Lambda to automate AMI & Snapshots deletion"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-07-24T11:34:11+01:00
draft: false
toc: false
images:
tags:
  - aws
  - python
---

- [Scenario](#scenario)
- [Steps](#steps)
   - [Create IAM Policy](#policy)
   - [Create IAM Role](#role)
   - [Create Lambda Function](#function)
   - [Add Cloudwatch Trigger](#trigger)

---

## Scenario{#scenario}

**Amazon Machine Images** are a great way to back up your AWS EC2 instances, for example before patching.  
However, there is no easy way to delete the Images afterwards. Each AMI has underlying **Elastic Block Store** (EBS) Snapshots attached to it, often many, which to delete require you to deregister the AMI and then find each Snapshot to then remove, via the AWS GUI. This can be time consuming and frustrating, and almost impossible if you're taking AMIs of many servers, for example before a patch cycle of hundreds of servers.

Fortunately there's an easy way to automate the deregistering of specific AMIs, as well as the deletion of underlying, related Snapshots, via a Python Lambda function.

In this scenario, we're going to assume that the images are all within the same AWS account and that we've applied a tag to them, with the format *Key=Purpose* and *Value=Patching*, which is easy to do at the time of taking the AMI.  
It is possible to use other critera for filtering, such as the age of the AMI, the title, etc., simply amend the Python code below to suit your needs.

**Note** : AWS Lambda functions are Region specific, so if you wish to clear down snapshots on the same account, from more than one Region, you will need to follow the steps below (for the Function creation and Cloudwatch Trigger) each Region you take AMIs in.

---

## Steps{#steps}

### Create an IAM Policy{#policy}

1. Use the search bar within the AWS GUI to search for *IAM* and navigate to it
2. On the left menu, select *Policies*
3. On the right side, click *Create Policy*
4. On the page that loads, Specify Permissions, select the *JSON view* in the top right
5. Paste in the following;
```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeImages",
				"ec2:DeregisterImage",
				"ec2:DescribeInstances",
				"ec2:DeleteSnapshot"
			],
			"Resource": "*"
		}
	]
}
```
6. Click *Next*
7. Name the policy, in this scenario I am using **ami-image-policy**
8. Fill in a Description and Tag(s), if you would like (optional)
9. Click *Create policy*

### Create an IAM Role{#role}

1. Still within IAM, on the left menu, select *Roles*
2. On the right side, click *Create role*
3. Select the Trusted entity type as *AWS Service*
4. Select the Use case and *Lambda*
5. Click *Next*
6. On the Permissions policies page, find and tick the Policy we created above, **ami-image-policy**
7. Click *Next*
8. Give your Role a name, in this case I used **ami-image-role**
9. Click *Create role*

### Create a Python Lambda Function{#function}

1. Use the search bar within the AWS GUI to search for *Lambda* and navigate to it
2. On the left menu, select *Functions*
3. On the right side, click *Create Function*
4. Select;
   1. Author from scratch
   2. Choose a Function name (in this scenario I'm going to use **ami-image-delete**)
   3. Select the Runtime as Python (in this scenario **Python 3.10**)
   4. Drop down *Change default execution role*, select *Use an existing role* and then select the role we created earlier; **ami-image-role**
   5. Leave everything else as default and select *Create function*
5. Under *Code source*, in the *lambda_function* tab, enter the code below. I've included some annotation throughout;

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
        ec2_client.deregister_image(ImageId=image_id)

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

6. *Deploy* the code
7. We don't want the task to time out after a moment (the default is 3 seconds), as it may take longer to run, so now go to the *Configuration* tab and click *Edit*
8. Set the *Timeout* to something sensible, based on how many Images you expect to be deleting in any one go. I would allocate at least a few seconds per Image. In my case, I set the timeout at 3 minutes.
9. (Optional) Take some EC2 AMI Images of servers on your AWS account
10. Back on the *Code* tab, click *Test* on the Lambda Function.
    1. If you are running the Function for the first time, you will get a window pop-up to *Configure test event*. Just give the event a name, anything will do, and click *Save*, then *Test* again.
    2. If you get an error stating "Task timed out after X seconds", revisit steps 7 and 8 above.

If it was successful, you should see an output like the following;

![An example of a jumpbox setup](../../images/ami_deletion_output.png)

### Create a Cloudwatch Trigger{#trigger}

Now we have a working script that deregisters AMIs and deletes underlying snapshots, we need to create a *CloudWatch* trigger so that it runs automatically on a regular basis.  
For this example, we're going to run the Function every Monday at 6pm.

1. Still within the Function overview within Lambda, click *Add trigger*;

![An example of a jumpbox setup](../../images/lambda_add_trigger.png)

2. Select *EventBridge (CloudWatch Events)* from the drop down
3. Under Rule, select *Create a new rule*
4. Name the rule whatever you like, for this scenario I used the same name as the function, **ami-image-delete**
5. Under Rule Type, select *Schedule expression*
6. I prefer cron for the expressions, so this covers every Monday at 6pm;
```
cron(00 18 ? * MON *)
```
Note that, by default, the time given is for UTC.

7. Click *Add*

---

[Top of page](#top)