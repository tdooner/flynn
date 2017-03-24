# flynn

## commands

```bash
CLUSTER_DOMAIN=f.tdooner.com flynn-host bootstrap --min-hosts 1
flynn cluster add [...sensitive args...]
```

## migrating
```
flynn create $(basename $(pwd))
heroku config --shell > config.sh
# remove database_url and redis_url
flynn env set $(cat config.sh)
flynn resource add postgres
flynn pg restore -f backup.psql
flynn route add [domain]
```

## setup
you will need various terraform variables to be set. The AWS account must have an IAM policy that look like:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "Stmt1480272070755",
    "Action": [
      "iam:AttachUserPolicy",
      "iam:CreateAccessKey",
      "iam:CreatePolicy",
      "iam:CreateUser",
      "iam:DeletePolicy",
      "iam:DeleteUser",
      "iam:DetachUserPolicy",
      "iam:GetPolicy",
      "iam:GetUser",
      "iam:GetUserPolicy",
      "iam:ListAccessKeys",
      "iam:ListEntitiesForPolicy",
      "iam:ListGroupsForUser",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:ListUserPolicies",
      "iam:ListUsers",
      "iam:PutUserPolicy",
      "iam:UpdateUser"
    ],
    "Effect": "Allow",
    "Resource": "arn:aws:iam::*"
  }]
}
```
