plate_thickness = 0; 
clip_height     = 12;
gap_x           = 40;
gap_z           = 40;
padding_x       = 5;
HS              = 1000;

module skadis_box(width=120, height=160, depth=60, wall=2, bottom=3) {
  back_plate_with_clips(width=width, height=height);
  front_box_on_plate(width=width, height=height, depth=depth, wall=wall, bottom=bottom);
}

module back_plate_with_clips(width, height) {
  translate([-width/2, -plate_thickness/2, 0])
    cube([width, plate_thickness, height]);

  W  = max(0, width - 2*padding_x);
  N  = max(1, floor(W/gap_x + 1));
  dx = -((N - 1)/2) * gap_x;

  H  = max(0, height - clip_height);
  NV = max(1, floor(H/gap_z + 1));

  for (i = [0 : N-1]) {
    for (j = [0 : NV-1]) {
      translate([dx + i*gap_x, -plate_thickness/2, j*gap_z])
        clip_pair(chamfer = (j > 0));
    }
  }
}

module clip_pair(chamfer=false) {
  union() {
    clip_single(chamfer=chamfer);                 
    mirror([1,0,0]) clip_single(chamfer=chamfer); 
  }
}

module clip_single(chamfer=false) {
  module clip_body() {
    linear_extrude(height=clip_height)
      rotate([0,0,180]) clip_profile();
  }

  if (chamfer) {
    difference() {
      clip_body();
      rotate([45, 0, 0])
        translate([-HS/2, -HS, -HS/2])
          cube([HS, HS, HS], center=false);
    }
  } else {
    clip_body();
  }
}

module clip_profile() {
  polygon(points=[
    [0.95, 0],
    [2.45, 0],
    [2.45, 3.7],
    [3.05, 4.3],
    [3.05, 5.9],
    [2.45, 6.5],
    [0.95, 6.5],
    [0.95, 0]
  ]);
}

module front_box_on_plate(width, height, depth, wall=2, bottom=3) {
  difference() {
    translate([-width/2, plate_thickness/2, 0])
      cube([width, depth, height]);

    translate([-(width/2) + wall, plate_thickness/2 + wall, bottom])
      cube([width - 2*wall, depth - 2*wall, height - bottom]);
  }
}

skadis_box(width=120, height=60, depth=20, wall=2, bottom=3);
