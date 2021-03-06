
common_folder = "C:/Users/oliveipa/Dropbox/Cluster project - Clean/"
design_folder = "6_sampling_location_bad/results"
sensitivity_folder = "4_typical_pump_situations"
epanet_folder = "3_network_modifications"

library(MASS) #necessary for ginv() function

possible_links_file = "summary_3flow.csv"

design_folder = paste(common_folder, design_folder,
                      sep = "")
sensitivity_folder = paste(common_folder, sensitivity_folder,
                           sep = "")
epanet_folder = paste(common_folder, epanet_folder,
                      sep = "")

##################################################
############# Link and node id lists #############
##################################################
setwd(epanet_folder)
node_id_list = read.table("node_id_list.csv", 
                          header = FALSE,
                          sep = ",",
                          colClasses = "character")
demand_node_id_list = read.table("demand_node_id_list.csv", 
                                 header = FALSE,
                                 sep = ",",
                                 colClasses = "character")
link_id_list = read.table("link_id_list.csv", 
                          header = FALSE,
                          sep = ",",
                          colClasses = "character")

node_id_list = node_id_list[,1]
demand_node_id_list = demand_node_id_list[,1]
link_id_list = link_id_list[,1]

n_nodes = length(node_id_list)
n_demand_nodes = length(demand_node_id_list)
n_links = length(link_id_list)

##################################################
######### Get flow sensitivity from file #########
##################################################
setwd(sensitivity_folder)
Q_sensitivity1 = read.table("Q_sensitivity_hour443.csv",
                            sep = ",")
Q_sensitivity2 = read.table("Q_sensitivity_hour448.csv",
                            sep = ",")
Q_sensitivity3 = read.table("Q_sensitivity_hour454.csv",
                            sep = ",")
Q_sensitivity4 = read.table("Q_sensitivity_hour481.csv",
                            sep = ",")

Q_sensitivity1 = as.matrix(Q_sensitivity1)
Q_sensitivity2 = as.matrix(Q_sensitivity2)
Q_sensitivity3 = as.matrix(Q_sensitivity3)
Q_sensitivity4 = as.matrix(Q_sensitivity4)

##################################################
############ Flow standard deviation ############
##################################################
setwd(epanet_folder)
links_mean = read.table(file = "model_Q_mean.csv",
                        sep = ",", header = FALSE)

sd_fraction = 5/100
links_sd = sd_fraction*links_mean[,2]
min_sd = 1 #equivalent to 20 gal/min, 50mm pipe with v=0.64m/s
change_pos = which(links_sd < min_sd)

links_sd_lim = links_sd
links_sd_lim[change_pos] = min_sd
links_var_lim = links_sd_lim^2

##################################################
###### Covariance for each pipe combination ######
##################################################
nodes_pos = match(demand_node_id_list ,node_id_list)
possible_links_list = NULL

#Vectors defined manually one by one
sensors_already_installed = c("20", "40", "50", 
                              "10", "329")
similar_pipes = c("60","330","333","125",
                  "133","101","335","201",
                  "289")

#Subsetting the sensors to search
sensors_to_search = link_id_list
remove_sensors = c(sensors_already_installed,
                   similar_pipes)
pos = match(remove_sensors, sensors_to_search)
sensors_to_search = sensors_to_search[-pos]
n_sensors = length(sensors_to_search)

#Calculating the uncertainty propagation
for(i in 1:(n_sensors-2)){
for(j in (i+1):(n_sensors-1)){
for(k in (j+1):n_sensors){

  link_id = c(sensors_to_search[i],
              sensors_to_search[j],
              sensors_to_search[k])

  sensor_ids = c(sensors_already_installed,
                 link_id)

  #Determining the covariance of the sensors
  sensor_pos = match(sensor_ids, link_id_list)
  measurement_var = diag(links_var_lim[sensor_pos])
  measurement_var_inverse = solve(measurement_var)
  
  demand_variance = 0

  #Epanet case 1
  Q_sensitivity_sensors = Q_sensitivity1[,sensor_pos]
  for(l in 1:n_demand_nodes){
    sigma2 = Q_sensitivity_sensors[l,] %*%
      measurement_var_inverse %*%
      cbind(Q_sensitivity_sensors[l,])
    sigma2 = 1 / sigma2
    demand_variance = demand_variance + sigma2
  }
  
  #Epanet case 2
  Q_sensitivity_sensors = Q_sensitivity2[,sensor_pos]
  for(l in 1:n_demand_nodes){
    sigma2 = Q_sensitivity_sensors[l,] %*%
      measurement_var_inverse %*%
      cbind(Q_sensitivity_sensors[l,])
    sigma2 = 1 / sigma2
    demand_variance = demand_variance + sigma2
  }
  
  #Epanet case 3
  Q_sensitivity_sensors = Q_sensitivity3[,sensor_pos]
  for(l in 1:n_demand_nodes){
    sigma2 = Q_sensitivity_sensors[l,] %*%
      measurement_var_inverse %*%
      cbind(Q_sensitivity_sensors[l,])
    sigma2 = 1 / sigma2
    demand_variance = demand_variance + sigma2
  }
  
  #Epanet case 4
  Q_sensitivity_sensors = Q_sensitivity4[,sensor_pos]
  for(l in 1:n_demand_nodes){
    sigma2 = Q_sensitivity_sensors[l,] %*%
      measurement_var_inverse %*%
      cbind(Q_sensitivity_sensors[l,])
    sigma2 = 1 / sigma2
    demand_variance = demand_variance + sigma2
  }
  
  results = as.numeric(c(sensor_ids, demand_variance/4))
  possible_links_list = rbind(possible_links_list,
                              results)

}  
}
}

setwd(design_folder)
write.table(possible_links_list, col.names = FALSE,
            file = possible_links_file,
            sep = ",", row.names = FALSE)
