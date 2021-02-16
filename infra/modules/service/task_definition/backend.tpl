[
  {
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "portMappings": [
      {
        "hostPort": ${load_balancer_port},
        "protocol": "tcp",
        "containerPort": ${container_port}
      }
    ],
    "cpu": ${cpu},
    "environment": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${region}"
      }
    ],
    "memoryReservation": ${memory},
    "image": "${image}",
    "healthCheck": {
        "retries": ${retry},
        "command": [
            "wget",
            "-qF",
            "--delete-after",
            "http://localhost:${container_port}/${path}"
        ],
        "timeout": ${timeout},
        "interval": ${interval},
        "startPeriod": ${start_period}
    },
    "entrypoint": ["npm", "start", "backend"],
    "volumesFrom": [],
    "essential": true,
    "name": "${env}"
  }
]