### 创建自定义授权

> 删除资源的权限
```json
{
    "Version": "1",
    "Statement": [
        {
            "Action": [
                "ram:CreatePolicy",
                "ram:CreatePolicyVersion",
                "ram:DeletePolicyVersion",
                "ram:SetDefaultPolicyVersion",
                "ecs:DeleteInstance",
                "ecs:DeleteSecurityGroup",
                "ecs:DeleteSnapshot",
                "rds:DeleteDatabase",
                "rds:DeleteDBInstance",
                "rds:DeleteAccount",
                "redis:DeleteInstance",
                "vpc:DeleteVSwitch",
                "vpc:DeleteVpc",
                "vpc:DeleteRouteEntry"
            ],
            "Resource": "*",
            "Effect": "Deny"
        }
    ]
}
```
> 删除策略权限
```json
{
    "Version": "1",
    "Statement": [
        {
            "Action": "*",
            "Effect": "Deny",
            "Resource": [
                "acs:ram:*:*:policy/admin-resource-deny",
                "acs:ram:*:*:policy/admin-ram-attach-deny",
                "acs:ram:*:*:policy/admin-ram-detach-deny"
            ]
        }
    ]
}
```
> 添加策略权限
```json
{
    "Version": "1",
    "Statement": [
        {
            "Action": "*",
            "Effect": "Deny",
            "Resource": [
                "acs:ram:*:*:policy/AliyunECSFullAccess",
                "acs:ram:*:*:policy/AliyunRDSFullAccess",
                "acs:ram:*:*:policy/AliyunKvstoreFullAccess",
                "acs:ram:*:*:policy/AliyunVPCFullAccess",
                "acs:ram:*:*:policy/AdministratorAccess",
                "acs:ram:*:*:policy/AliyunRAMFullAccess"
            ]
        }
    ]
}
```
