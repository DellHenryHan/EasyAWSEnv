# Easy Environment in AWS

This project helps you set up instances with configurations quickly in AWS

### Prerequisites

it only requires a configuration file(.ini) providing the instance information. Refer to myinstance.ini in the folder InstanceSample. The file consists of the following part:

```
[GLOBAL]
...
[INSTANCE1]
...
[INSTANCE2]
...
```
Every section stands for an instance with its parameters, except GLOBAL which has the shared parameters for all the instances, which means the parameters under the section GLOBAL are for all the other sections, and they'll override the parameters under the other sections if they have the same parameter names.

These are the parameters required for an instance. 

| parameter name        | description   |  example  |
| --------   | :-----  | :----  |
| ImageId     | the image id for the instance, it should be quoted if it is a tring, it can also be the value used in [cloudformation template](http://docs.aws.amazon.com/zh_cn/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html)  |   ImageId="ami-221dcb4f"|
| InstanceType        |   the instance type   |   InstanceType=m1.large   |
| DiskSize        |   the disk size   |   DiskSize="60"   |
| SubnetId        |   the subnet id. it should be quoted if it is a tring, it can also be the value used in cloudformation template   |   SubnetId={ "Fn::ImportValue": "PreSubnet" }   |
| Role       |    the Role of the instance, the value depends on what template name you'll use. If it's template_instance, you can just set it to Default; if it's template_spotfleet, you should choose Dc for domain controler, Member for the members under the domain controller and Default if it is an independent one.    |  Role=Default  |

These are optional parameters

| parameter name        | description   |  example  |
| --------   | :-----  | :----  |
|InstanceName|the instance name|InstanceName=myinstance_dc|
|DC|the section name of the domain controller that current instance will join|DC=dc|
|InstanceRoleProfile|the instance profile for the instance, it should be quoted if it is a tring, it can also be the value used in cloudformation template|InstanceRoleProfile={ "Fn::ImportValue": "PreRoleProfileName" }|
|Step*|the Powershell scripts for instance configuration, the scripts will be executed ordered by the number after "Step", e.g. step1, step2 ..., Restart-Computer is allowed among the steps;the scripts should not be as simple as possible; complicate scripts is recommended to be stored somewhere, downloaded and executed within the steps|Step1=Get-Host, step2=restart-computer|

You can also have self defined parameters, and all the parameters will be set as environment variables of Windows system that can be used for later configuration.
### Generate Cloudformation Template

Clone this repository

```
Git Clone https://github.com/DellHenryHan/EasyAWSEnv.git
```

Generate Cloudformation template with powershell, select proper templates according to the way you start instance, use the ini file described above. The target file will be %temp%\temp.json, you can also specify it with the parameter -outfile

```
. .\file_handler.ps1
Make-CfFile -IniFile .\myinstance.ini -templatePath .\templates_instance
```

## Start specific instances

Go to AWS console for [Cloudformation](https://console.aws.amazon.com/cloudformation) and create a stack with the template generated. Wait for the launch and the instances
