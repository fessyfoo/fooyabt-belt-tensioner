use <threads.scad>;

$fs=0.1;
$fa=3;

// 4.6 pully puller wall
// 10.8 pully gap
// 4.3 pully puller nub
// 5.5 hole for pully bolt

range              = 10; // range of movement.
d_pulley           = 22;
w_pulley           = 11;
d_pulley_axel_hole = 5.5; // m5 + tolerance
w_extrusion        = 20;
d_puller           = 24;
d_puller_tol       = d_puller + 1;
puller_pillar_tol  = 0.5;
h_t_nut_flange     = 10;
thickness          = 4;
pitch              = 2;

h_case   = range + d_pulley + thickness * 2;
h_nut    = thickness > 2*pitch ? ceil(thickness/pitch)*pitch : 2*pitch;
h_puller = d_pulley + range + thickness*1.5 + h_nut;

function hyp(a,b) = sqrt(pow(a,2) + pow(b,2));

module translate_z (h) {
  translate([0,0,h]) children();
}

module nut(tol=0.75) {
  echo("nut tolerance = ", tol);
  w = thickness;
  dI = d_puller + tol * 2;
  dO = w*2 + dI;


  difference() {
    cylinder(d=dO, h=h_nut);
    translate([0,0,-0.01]) metric_thread(
      diameter    = dI,
      length      = h_nut+0.02,
      internal    = true,
      pitch       = pitch,
      leadin      = 0
    );
  }

  c = dO * PI; 
  n = floor(c/w/2);
  for (i=[0:360/n:360]) {
    rotate(i)
    translate([dO/2,0,0])
    cylinder(d=w, h=h_nut * 0.75);
  }
}

module test_thread(h=10,pitch=pitch) {
  wC = d_puller / 2;
  translate([-wC/2,-wC/2]) 
    cube([wC, wC, h*2]);
  metric_thread(
    diameter=d_puller,
    length=h+2,
    internal=false,
    pitch = pitch,
    leadin = 2,
    leadinfac = 2
  );
}


module puller(fast=false) {
  h_total   =  h_puller;
  h_threads = h_total - (d_pulley + d_pulley_axel_hole) * 2/3;
  h_base    = h_total - h_threads;

  difference() {
    union () {
      if (fast) {
        cylinder(d=d_puller, h=h_total);
      } else {
        cylinder(d=d_puller, h=h_base);
        translate([0,0,h_base]) metric_thread(
          diameter    = d_puller,
          length      = h_threads,
          internal    = false,
          pitch       = pitch,
          leadin      = 1,
          leadinfac   = 2
        );
      }
    }

    //dn = sqrt(pow(d_puller,2)*2);
    dn = hyp(d_puller, d_puller);
    echo(dn=dn);

    translate([-dn/2,-(w_pulley + 1)/2,-1]) 
      cube([dn, w_pulley + 1, d_pulley + 2]);

    translate_z(d_pulley/2) {

      // axel holes
      rotate([90,0,0])
        translate([0,0,-(d_puller + 2)/2])
          cylinder(d=d_pulley_axel_hole, h=d_puller + 2);

      // hex cutouts, keep stock size bolt fitting.
      d_pulley_nut_hole = 10;
      difference() {
        rotate([90,90,0])
          translate_z(-(d_puller + 2)/2)
            cylinder($fn = 6, d=d_pulley_nut_hole, h=d_puller + 2);
        cube([10,w_extrusion,10], center=true);
      }
    }

    // square notches
    translate_z(-thickness)
      base_pillars(height=h_total, cutouts = true);

  }


}

module base_pillars(
  cutouts = false,
  height  = d_pulley + 10 + 2,
  tol     = puller_pillar_tol
) {
  lS  = cutouts ? 5.9 : 5.9 + tol;
  for (i=[0:3]) {
    rotate(i*90)
    translate([lS,lS,-1])
    cube([d_puller, d_puller, height]);
  }
}

module case () {
  w_flanges = thickness;
  h_case = h_case;
  d_case = d_puller + w_flanges * 2;
  w_case = w_extrusion + w_flanges * 2;
  w_channel = (5.9 + puller_pillar_tol) * 2;
  h_channel = h_case - w_flanges * 3;

  difference() {
    hull() {
      cylinder(d=d_case, h=h_case);
      translate([0,0,w_flanges/2])
        cube([w_case, w_case, w_flanges], center=true);
    }

    rotate(90)
    translate([0,0, h_channel / 2 + w_flanges * 2])
      cube([d_case + 2, w_channel, h_channel], center=true);

    translate([0,0, (h_channel + w_flanges*2) / 2 - 1 ])
      cube([d_case + 2, w_channel, h_channel + w_flanges*2 + 2], center=true);

    translate([0,0,w_flanges/2])
      cube([w_extrusion + 0.5, w_extrusion + 0.5, w_flanges + 1], center=true);

    translate([0,0,w_flanges])
    difference() {
      translate([0,0,-1]) 
      cylinder(d=d_puller_tol, h = h_case + w_flanges * 2 + 2);
      translate([0,0,-1]) 
      base_pillars(height = h_case + w_flanges * 2 + 4);
    }

  }

}

module assembly () {
  case();
  translate_z(thickness) puller();
  translate_z(h_case + 0.4 ) nut();
}

module flip(height) {
   
   translate_z(height/2) 
   rotate([180,0,0])
   translate_z(-height/2) 
   children();
}

module plate() {
  offset = d_puller + thickness * 2;
  rotate(0)   translate([offset,0,0]) nut();
  rotate(120) translate([offset,0,0]) flip(h_case) case();
  rotate(240) translate([offset,0,0]) flip(h_puller) puller();
}

module display() {
  rotate(45) assembly();
  translate([45,0,0]) rotate(45) case();
  translate([90,0,0]) rotate(45) puller();
  translate([135,0,0]) nut();
}

module test_hex_nut_hole() {
  rotate([90,0,0])
    intersection() {
      translate([-10,0,0]) cube(20);
      translate([0,-(w_pulley+1)/2,0])
      puller();
    }
}

display();
