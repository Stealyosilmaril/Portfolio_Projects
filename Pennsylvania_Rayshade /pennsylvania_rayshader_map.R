library(tigris)
library(tidyverse)
library(sf)
library(crsuggest)
library(stars)
library(rayshader)
library(units)
library(colorspace)
library(MetBrewer)

#WGS 84 3857 geopackage of US portion of Kontur
hexagons <- st_read("data/US.gpkg")


#NAD83 4269 tigris 
state <- states()

#filtering out other US states 
penn <- state |> 
  filter(NAME == "Pennsylvania")

#changing the coordinates of the census data so that things match up
pa <- st_transform(penn, 3857)

#test
pa |>
  ggplot() +
  geom_sf()

#confining coordinates to only PA state
state_pa <- st_intersection(hexagons, pa)

#creating bounding box for our future map
bb <- st_bbox(state_pa)

bottom_left <- st_point(c(bb[["xmin"]], bb[["ymin"]])) |>
  st_sfc(crs = st_crs(hexagons))

bottom_right <- st_point(c(bb[["xmax"]], bb[["ymin"]])) |>
  st_sfc(crs = st_crs(hexagons))

# plotting points to check 
pa |>
  ggplot() +
  geom_sf() +
  geom_sf(data = bottom_left) +
  geom_sf(data = bottom_right, color = "red")

width <- st_distance(bottom_left, bottom_right)

top_left <- st_point(c(bb[["xmin"]], bb[["ymax"]])) |>
  st_sfc(crs = st_crs(hexagons))

height <- st_distance(bottom_left, top_left)

# handle conditions of width or height as longer side

if (width > height) {
  w_ratio <- 1
  h_ratio <- height / width
} else {
  h_ratio <- 1
  w_ratio <- width / height 
}

# convert to raster as intermediary for matrix conversion
size <- 5000
pa_rast <- st_rasterize(state_pa,
                            nx = floor(size * w_ratio),
                            ny = floor(size * h_ratio)
)

mat <- matrix(pa_rast$population, 
              nrow = floor(size * w_ratio),
              ncol = floor(size * h_ratio))
#getting the colors (credit to Spencer Schien for the color ideas)
c1 <- met.brewer("OKeeffe2")
swatchplot(c1)

texture <- grDevices::colorRampPalette(c1, bias = 2)(256)
swatchplot(texture)

#maybe closed3 is better option now
rgl::rgl.close()

#rough render with rayshader
mat |>
  height_shade(texture = texture) |>
  plot_3d(heightmap = mat,
          zscale = 100/4,
          solid = FALSE,
          shadowdepth = 0)

#different angles I want of final map 
  #render_camera(theta = 75, phi = 8, zoom = .4)
  # render_camera(theta = 90, phi = 15, zoom = .55)
render_camera(theta = 85, phi = 20, zoom = .55)

#final render with lengthy inputs
render_highquality(
  filename = "images/state6.png",
  interactive = FALSE,
  lightaltitude = c(20, 80),
  lightcolor = c(c1[2], "white"), 
  lightintensity = c(600, 100),
  samples = 450,
  width = 6000,
  height = 6000
)

#creating text to be added to image
library(magick)
image <- image_read("images/replica.png") 

colors <- met.brewer("OKeeffe2")
swatchplot(colors)

text_color <- darken(colors[7], .5)
swatchplot(text_color)

annotate <- glue("This state map is made up of hexagons.",
                 " Each hexagon corresponds to a 400m area of people.") |> 
  str_wrap(45)

image |> 
  image_crop(gravity = "center",
             geometry = "5700x4000") |>
  image_annotate("Pennsylvania Population Density",
                        gravity = "northwest",
                        location = "+200+100",
                        color = text_color,
                        size = 200, 
                        weight = 700,
                        font = postscriptFonts("Palatino Linotype")) |>
  image_annotate(annotate,
                 gravity = "northwest",
                 location = "+200+500",
                 color = text_color,
                 size = 125,
                 font = postscriptFonts("Palatino Linotype")) |> 
  image_annotate(glue("visualized by Shane Manske (github@stealyosilmaril) from the ",
                      "Kontur Population Dataset (2022)"),
                 gravity = "southwest",
                 location = "0+100",
                 font = postscriptFonts("Palatino Linotype"),
                 color = alpha(text_color, .5),
                 size = 70) |>
  image_write("images/replica_final.png") 
  
