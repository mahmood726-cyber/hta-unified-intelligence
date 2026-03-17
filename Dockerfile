# HTA UNIFIED INTELLIGENCE SYSTEM - REPRODUCIBILITY CONTAINER
FROM rocker/tidyverse:4.2.0

# Install Python and Pip
RUN apt-get update && apt-get install -y python3 python3-pip

# Set working directory
WORKDIR /app

# Copy dependency files
COPY requirements.txt setup.R ./

# Install R dependencies
RUN Rscript setup.R

# Install Python dependencies
RUN pip3 install -r requirements.txt

# Copy the rest of the project
COPY . .

# Run the pipeline by default
CMD ["Rscript", "master_integration_pipeline.R"]
