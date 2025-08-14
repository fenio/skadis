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
engrave_text  = "";           // Leave empty to disable text
engrave_size  = 12;            // Text size in mm
engrave_depth = 0.8;           // Depth/height of text (mm). Used for both engraved and embossed
engrave_font  = "";           // Example: "Liberation Sans:style=Bold"; empty uses OpenSCAD default
text_emboss   = false;         // If true, text is embossed (raised). If false, engraved (recessed)
text_round_radius = 0.3;       // Rounds glyph corners (mm) to avoid sharp edges
text_epsilon = 0.1;            // Small overlap (mm) to avoid coplanar CSG issues

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

// Text geometry helper: rounded glyphs extruded along +Y in local space
module front_text_geometry(depth_amount) {
  linear_extrude(height=depth_amount)
    mirror([1,0,0])
      if (text_round_radius > 0)
        offset(r=text_round_radius)
          text(text=engrave_text, size=engrave_size, font=engrave_font, halign="center", valign="center");
      else
        text(text=engrave_text, size=engrave_size, font=engrave_font, halign="center", valign="center");
}

// Place embossed (raised) text on the front face
module add_front_text_emboss(width, height, depth) {
  translate([0, plate_thickness/2 + depth + text_epsilon, height/2])
    rotate([90, 0, 0])
      front_text_geometry(engrave_depth);
}

// Place engraved (recessed) text volume to subtract from the front face
module subtract_front_text_engrave(width, height, depth, wall) {
  fd = min(engrave_depth, max(wall - 0.2, 0.1));
  translate([0, plate_thickness/2 + depth - fd - text_epsilon, height/2])
    rotate([-90, 0, 0])
      front_text_geometry(fd);
}

module front_box_on_plate(width, height, depth, wall=2, bottom=3, fillet_radius=0) {
  fr = max(0, fillet_radius);
  if (fr <= 0) {
    if (engrave_text != "") {
      if (text_emboss) {
        // Emboss: add raised text on the outside, then hollow the box
        difference() {
          union() {
            translate([-width/2, plate_thickness/2, 0])
              cube([width, depth, height]);
            add_front_text_emboss(width, height, depth);
          }
          translate([-(width/2) + wall, plate_thickness/2 + wall, bottom])
            cube([width - 2*wall, depth - 2*wall, height - bottom]);
        }
      } else {
        // Engrave: subtract rounded text from the front wall
        difference() {
          translate([-width/2, plate_thickness/2, 0])
            cube([width, depth, height]);

          translate([-(width/2) + wall, plate_thickness/2 + wall, bottom])
            cube([width - 2*wall, depth - 2*wall, height - bottom]);

          subtract_front_text_engrave(width, height, depth, wall);
        }
      }
    } else {
      // No text
      difference() {
        translate([-width/2, plate_thickness/2, 0])
          cube([width, depth, height]);

        translate([-(width/2) + wall, plate_thickness/2 + wall, bottom])
          cube([width - 2*wall, depth - 2*wall, height - bottom]);
      }
    }
  } else {
    if (engrave_text != "") {
      if (text_emboss) {
        // Embossed with rounded shell
        difference() {
          union() {
            translate([-width/2, plate_thickness/2, 0])
              linear_extrude(height=height)
                rounded_rect_2d(width, depth, fr);
            add_front_text_emboss(width, height, depth);
          }
          translate([-width/2, plate_thickness/2, bottom])
            linear_extrude(height=height - bottom)
              offset(delta=-wall)
                rounded_rect_2d(width, depth, fr);
        }
      } else {
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

          // Engraved text subtraction
          subtract_front_text_engrave(width, height, depth, wall);
        }
      }
    } else {
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
}

skadis_box(width=width, height=height, depth=depth, fillet_radius=wall_fillet_radius);
