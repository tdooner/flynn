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
