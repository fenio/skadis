/* [Box Size] */
width = 120;
height = 60;
depth = 20;

/* [Hidden] */
plate_thickness = 0; 
clip_height     = 12;
gap_x           = 40;
gap_z           = 40;
padding_x       = 5;
HS              = 1000;

/* [Fillet] */
wall_fillet_radius = 0; // set > 0 to enable wall fillet

/* [Text] */
front_text = "";                             // text content; leave empty to disable
front_text_embossed = false;                  // false = engraved, true = embossed
front_text_size = 12;                         // font size in mm
front_text_depth = 1.0;                       // emboss/engrave depth in mm (along Y)
front_text_font = "Liberation Sans:style=Bold"; // OpenSCAD font spec
front_text_halign = "center";               // left | center | right
front_text_valign = "center";               // top | center | baseline | bottom
front_text_spacing = 1.0;                    // letter spacing multiplier
front_text_rotation = 0;                      // rotation in degrees within the face plane
front_text_offset_x = 0;                      // offset along X on the front face (mm)
front_text_offset_z = 0;                      // offset along Z on the front face (mm)

module skadis_box(width=120, height=160, depth=60, wall=2, bottom=3, fillet_radius=0) {
  back_plate_with_clips(width=width, height=height);
  front_box_on_plate(width=width, height=height, depth=depth, wall=wall, bottom=bottom, fillet_radius=fillet_radius);
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

// 2D rounded rectangle helper using offset for rounded joins
module rounded_rect_2d(w, d, r) {
  // Ensure non-negative radius and feasible dimensions
  rr = max(0, r);
  // Round corners by expanding and shrinking the rectangle footprint
  offset(r=rr) offset(delta=-rr) square([w, d], center=false);
}

// Generate 3D text positioned on the front face; embossed controls orientation and additional flip
module front_text_shape(width, height, depth, is_embossed=false) {
  has_text = (len(front_text) > 0);
  if (has_text) {
    y_front = plate_thickness/2 + depth;
    eps = 0.02;


    if (is_embossed) {
      // Emboss: start just outside the front face and extrude inward (net union creates outside bump)
      translate([front_text_offset_x, y_front + eps, (height/2) + front_text_offset_z])
        // Rotate 180° around X as requested; total 270° to keep front-face orientation while flipping glyph
        rotate([270, 0, 0])
          linear_extrude(height=front_text_depth)
            rotate([0, 0, front_text_rotation])
              text(front_text, size=front_text_size, font=front_text_font, halign=front_text_halign, valign=front_text_valign, spacing=front_text_spacing);
    } else {
      // Engrave: start slightly outside and cut inward (-Y) so it is visible on the surface
      translate([front_text_offset_x, y_front + eps, (height/2) + front_text_offset_z])
        rotate([90, 0, 0])
          linear_extrude(height=front_text_depth)
            rotate([0, 0, front_text_rotation])
              text(front_text, size=front_text_size, font=front_text_font, halign=front_text_halign, valign=front_text_valign, spacing=front_text_spacing);
    }
  }
}

module front_box_on_plate(width, height, depth, wall=2, bottom=3, fillet_radius=0) {
  fr = max(0, fillet_radius);

  // Base box geometry (hollow), independent of text treatment
  module base_box() {
    if (fr <= 0) {
      difference() {
        translate([-width/2, plate_thickness/2, 0])
          cube([width, depth, height]);

        translate([-(width/2) + wall, plate_thickness/2 + wall, bottom])
          cube([width - 2*wall, depth - 2*wall, height - bottom]);
      }
    } else {
      // Use 2D rounded rectangle extruded along Z to form the box with filleted walls
      difference() {
        // Outer shell
        translate([-width/2, plate_thickness/2, 0])
          linear_extrude(height=height)
            rounded_rect_2d(width, depth, fr);

        // Inner cavity: offset inward by wall to maintain thickness around corners, preserve bottom
        translate([-width/2, plate_thickness/2, bottom])
          linear_extrude(height=height - bottom)
            offset(delta=-wall)
              rounded_rect_2d(width, depth, fr);
      }
    }
  }

  // Apply text as engraved or embossed on the front face
  has_text = (len(front_text) > 0);
  if (has_text && !front_text_embossed) {
    difference() {
      base_box();
      front_text_shape(width, height, depth, is_embossed=false);
    }
  } else if (has_text && front_text_embossed) {
    union() {
      base_box();
      front_text_shape(width, height, depth, is_embossed=true);
    }
  } else {
    base_box();
  }
}

skadis_box(width=width, height=height, depth=depth, fillet_radius=wall_fillet_radius);
