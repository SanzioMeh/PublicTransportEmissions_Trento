library(gtfs2emis)
library(gtfs2gps)
library(dplyr)
library(gtfsr)

fleet_df <- data.frame(
  veh_type = c(
    "Ubus Std 15 - 18 t", "Ubus Std 15 - 18 t", "Ubus Std 15 - 18 t", "Ubus Std 15 - 18 t",
    "Ubus Std 15 - 18 t", "Ubus Std 15 - 18 t", "Ubus Std 15 - 18 t"),
  euro = c("I", "III", "IV", "V", "VI", "EEV", "II"),
  fuel = c("CNG", "D", "D", "D", "D", "CNG", "CNG"),
  N = c(25, 32, 1, 9, 72, 9, 67),
  fleet_composition = c(0.119, 0.152, 0.005, 0.043, 0.343, 0.043, 0.319),
  tech = c("-", "-", "SCR", "SCR", "DPF+SCR", "-", "-"),
  stringsAsFactors = FALSE
)

# Round composition for readability
fleet_df$fleet_composition <- round(fleet_df$fleet_composition, 6)

print(fleet_df)

gtfs <- read_gtfs("google_transit_urbano_tte.zip")

# We are going to remove local routes outside of Trento
routes_to_remove <- c(578, 580, 582, 590, 592, 594, 598, 601, 602, 605, 
                      607, 610, 612, 613, 512, 562, 563, 566, 531)

gtfs$routes <- gtfs$routes %>%
  filter(!route_id %in% routes_to_remove)

gtfs$trips <- gtfs$trips %>%
  filter(!route_id %in% routes_to_remove)

gtfs$stop_times <- gtfs$stop_times %>%
  filter(trip_id %in% gtfs$trips$trip_id)

#First part: transport model
tp_model <- transport_model(gtfs_data = gtfs,spatial_resolution = 100,parallel = TRUE) 
#Second part: emission model
emi_list <- emission_model(tp_model = tp_model
                           , ef_model = "ef_europe_emep"
                           , fleet_data = fleet_df
                           , pollutant = c("NOx","PM10", "CO")
)
emi_list
emis_table <- emi_list$emi
names(emi_list)
names(emis_table)

write.csv(emis_table, "emissions_output.csv", row.names = FALSE)
print(emis_table)

# Manually replace the names
colnames(emis_table) <- c(
  "NOx_Euro_I_CNG", "NOx_Euro_III_D", "NOx_Euro_IV_D", "NOx_Euro_V_D", "NOx_Euro_VI_D", "NOx_Euro_EEV", "NOx_Euro_II_CNG",
  "PM10_Euro_I_CNG", "PM10_Euro_III_D", "PM10_Euro_IV_D", "PM10_Euro_V_D", "PM10_Euro_VI_D", "PM10_Euro_EEV", "PM10_Euro_II_CNG",
  "CO_Euro_I_CNG", "CO_Euro_III_D", "CO_Euro_IV_D", "CO_Euro_V_D", "CO_Euro_VI_D", "CO_Euro_EEV", "CO_Euro_II_CNG"
)
emis_table

# Function to remove unit text and convert to numeric, as the emis_table contains the [g] at the end
clean_numeric <- function(x) {
  as.numeric(gsub("\\s*\\[.*\\]", "", x))
}

# Apply cleaning and sum each column
emis_sums <- sapply(emis_table, function(col) sum(clean_numeric(col), na.rm = TRUE))

# Print sums
print(emis_sums)


