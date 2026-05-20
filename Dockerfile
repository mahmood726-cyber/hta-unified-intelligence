# HTA UNIFIED INTELLIGENCE SYSTEM - REPRODUCIBILITY CONTAINER
FROM rocker/tidyverse:4.3.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt setup.R ./
RUN Rscript setup.R
RUN pip3 install --break-system-packages -r requirements.txt

COPY . .

CMD ["bash", "run_all_unified.sh"]
