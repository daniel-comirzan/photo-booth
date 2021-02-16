FROM ubuntu:latest

ARG TF_VER=0.13.5
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam

RUN apt-get update && apt-get -y install \
    sudo \
    tzdata \
    make \
    zip  \
    curl \
    jq   \
    git  \
    golang \
    python3 \
    python3-pip

RUN pip3 install --upgrade pip ; \
    apt-get clean

RUN pip3 --no-cache-dir install --upgrade awscli && \
    curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash && \
    tfswitch $TF_VER

RUN curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    git clone https://github.com/terraform-linters/tflint-ruleset-aws.git && cd tflint-ruleset-aws && make && make install

RUN echo 'alias run=scripts/run_terraform.sh >> /root/.bash_aliases '

WORKDIR /app

CMD ["/bin/bash"]