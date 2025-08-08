library(gtfs2emis)
library(gtfs2gps)

fleet_df <- data.frame(
  veh_type = rep("Ubus Std 15 - 18 t", 6),
  euro = c("VI", "III", "IV", "V", "VI", "VI"),
  fuel = c("CNG", "D", "D", "D", "D", "BD"),
  N = c(92, 32, 1, 9, 72, 9),
  fleet_composition = c(
    92 / (92 + 114 + 9),
    32 / (92 + 114 + 9),
    1 / (92 + 114 + 9),
    9 / (92 + 114 + 9),
    72 / (92 + 114 + 9),
    9 / (92 + 114 + 9)
  ),
  tech = c("-", "-", "SCR", "SCR", "DPF+SCR", "-")
)

# Round composition for readability
fleet_df$fleet_composition <- round(fleet_df$fleet_composition, 6)

print(fleet_df)

gtfs <- read_gtfs("google_transit_urbano_tte.zip")  # Replace with your GTFS file


tp_model <- transport_model(gtfs_data = gtfs,spatial_resolution = 100,parallel = TRUE) 



emi_list <- emission_model(tp_model = tp_model
                           , ef_model = "ef_europe_emep"
                           , fleet_data = fleet_df
                           , pollutant = c("NOx","PM10")
)
emi_list
