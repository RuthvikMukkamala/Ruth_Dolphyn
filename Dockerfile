# Use the official Julia image as a base
FROM julia:1.10.4

# Set the working directory
WORKDIR /app

# Copy the project files into the Docker image
COPY . /app

# Install required Julia packages
RUN julia -e 'using Pkg; Pkg.add("Dolphyn"); Pkg.add("HiGHS"); Pkg.add("JuMP"); Pkg.add("Gurobi")'

# Install Gurobi solver (optional, if using Gurobi)

RUN julia -e 'using Pkg; Pkg.build("Gurobi")'

# Command to run the model
CMD ["julia", "Run.jl"]

# Expose necessary ports if any (optional)
# EXPOSE 8080
