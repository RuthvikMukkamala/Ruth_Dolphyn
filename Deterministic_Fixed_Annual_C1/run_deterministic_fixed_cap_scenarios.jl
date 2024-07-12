using CSV
using DataFrames

file_path = @__DIR__
# Import scenarios of interest and store directory names in a Dataframe
Scenario_Param = CSV.read(joinpath(file_path, "Scenario_file_deterministic_fixed_cap.csv"), DataFrame)

# Call directory in row c Scenario_Param[!,:dir_name][c]

#print(dirnames)

# Grab the argument that is passed in
# This is the index into fnames for this process
task_id = parse(Int,ARGS[1])
num_tasks = parse(Int,ARGS[2])

print(task_id)
print(num_tasks)

for dir in task_id+1:num_tasks:size(Scenario_Param)[1]
    print(string(Scenario_Param[!,:dir_name][dir]))
    include(string(Scenario_Param[!,:dir_name][dir])*"/Run.jl")
end


