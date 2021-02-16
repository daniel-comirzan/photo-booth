#!/usr/bin/env bash
cat << EOF > /etc/ecs/ecs.config
  ECS_CLUSTER=${cluster_name}
  ECS_DATADIR=/data
  ECS_LOGFILE=/log/ecs-agent.log
  ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
  ECS_LOGLEVEL=info
  ECS_ENABLE_CONTAINER_METADATA=true
EOF