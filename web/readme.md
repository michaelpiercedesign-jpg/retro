## Mapnik for lambda:




        npm install mapnik@3.7.0 --target=8.10.0 --target_arch=x64 --target_platform=linux --save

From [here](https://github.com/arun-gupta/serverless/tree/master/lambda-rds).

# Create

    AWS_PROFILE=bnolan aws rds create-db-instance \
        --db-instance-identifier cryptovoxel \
        --db-instance-class db.t2.micro \
        --engine postgres \
        --port 3006 \
        --allocated-storage 5 \
        --db-name cryptovoxel \
        --master-username masterrdsuser \
        --master-user-password ... \
        --backup-retention-period 3 \
        --region us-east-2

## Permissions

    AWS_PROFILE=bnolan aws rds describe-db-instances --region us-east-2 | jq ".DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId"

    AWS_PROFILE=bnolan aws ec2 authorize-security-group-ingress --group-id sg-71e62c18 --protocol all --port 3006 --cidr 0.0.0.0/0 --region us-east-2

    AWS_PROFILE=bnolan aws rds describe-db-instances --region us-east-2 | jq ".DBInstances[0].Endpoint.Address"

## psql!

    psql --host cryptovoxel.cxaycwb5mcou.us-east-2.rds.amazonaws.com --port 3006 --user masterrdsuser cryptovoxel

    cat ../../boxproject/server/migrations.sql | psql --host cryptovoxel.cxaycwb5mcou.us-east-2.rds.amazonaws.com --port 3006 --user masterrdsuser cryptovoxel

    DATABASE_URL=postgres://masterrdsuser:...@cryptovoxel.cxaycwb5mcou.us-east-2.rds.amazonaws.com:3006/cryptovoxel

# Delete (careful)

    AWS_PROFILE=bnolan aws rds delete-db-instance \
        --db-instance-identifier cryptovoxel-test \
        --skip-final-snapshot \
        --region us-east-2

# Datas

    {
        "DBInstance": {
            "PubliclyAccessible": true,
            "MasterUsername": "masterrdsuser",
            "MonitoringInterval": 0,
            "LicenseModel": "postgresql-license",
            "VpcSecurityGroups": [
                {
                    "Status": "active",
                    "VpcSecurityGroupId": "sg-71e62c18"
                }
            ],
            "CopyTagsToSnapshot": false,
            "OptionGroupMemberships": [
                {
                    "Status": "in-sync",
                    "OptionGroupName": "default:postgres-9-6"
                }
            ],
            "PendingModifiedValues": {
                "MasterUserPassword": "****"
            },
            "Engine": "postgres",
            "MultiAZ": false,
            "DBSecurityGroups": [],
            "DBParameterGroups": [
                {
                    "DBParameterGroupName": "default.postgres9.6",
                    "ParameterApplyStatus": "in-sync"
                }
            ],
            "AutoMinorVersionUpgrade": true,
            "PreferredBackupWindow": "03:52-04:22",
            "DBSubnetGroup": {
                "Subnets": [
                    {
                        "SubnetStatus": "Active",
                        "SubnetIdentifier": "subnet-dc7295a7",
                        "SubnetAvailabilityZone": {
                            "Name": "us-east-2b"
                        }
                    },
                    {
                        "SubnetStatus": "Active",
                        "SubnetIdentifier": "subnet-c5a8ad8f",
                        "SubnetAvailabilityZone": {
                            "Name": "us-east-2c"
                        }
                    },
                    {
                        "SubnetStatus": "Active",
                        "SubnetIdentifier": "subnet-da0ed9b3",
                        "SubnetAvailabilityZone": {
                            "Name": "us-east-2a"
                        }
                    }
                ],
                "DBSubnetGroupName": "default",
                "VpcId": "vpc-5706fc3e",
                "DBSubnetGroupDescription": "default",
                "SubnetGroupStatus": "Complete"
            },
            "ReadReplicaDBInstanceIdentifiers": [],
            "AllocatedStorage": 5,
            "DBInstanceArn": "arn:aws:rds:us-east-2:429954616046:db:cryptovoxel",
            "BackupRetentionPeriod": 3,
            "DBName": "cryptovoxel",
            "PreferredMaintenanceWindow": "fri:07:55-fri:08:25",
            "DBInstanceStatus": "creating",
            "IAMDatabaseAuthenticationEnabled": false,
            "EngineVersion": "9.6.6",
            "DomainMemberships": [],
            "StorageType": "standard",
            "DbiResourceId": "db-DG4OSN2YH4KNYTOXEPLPSA3IQI",
            "CACertificateIdentifier": "rds-ca-2015",
            "StorageEncrypted": false,
            "DBInstanceClass": "db.t2.micro",
            "DbInstancePort": 0,
            "DBInstanceIdentifier": "cryptovoxel"
        }
    }
