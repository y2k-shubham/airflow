#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -e

: "${AIRFLOW__CORE__FERNET_KEY:=${FERNET_KEY:=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")}}"

export AIRFLOW__SCHEDULER__STATSD_HOST

if test "$AWS_EXECUTION_ENV" = "AWS_ECS_EC2"
then
  instance_ip=$(curl --silent http://169.254.169.254/1.0/meta-data/local-ipv4)
  AIRFLOW__SCHEDULER__STATSD_HOST=$instance_ip
fi
echo statsd host is "$AIRFLOW__SCHEDULER__STATSD_HOST"

echo Starting Apache Airflow with command:
echo airflow "$@"

exec airflow "$@"
