use <threads.scad>;

$fs=0.1;
$fa=3;

// 4.6 pully puller wall
// 10.8 pully gap
// 4.3 pully puller nub
// 5.5 hole for pully bolt

d_pulley           = 22;
w_pulley           = 11;
w_pulley_axel_hole = 5.5; // m5 + tolerance
w_extrusion        = 20;
d_puller           = 24;
d_puller_tol       = d_puller + 1;
pitch              = 2;

function hyp(a,b) = sqrt(pow(a,2) + pow(b,2));

module nut(tol=0.75) {
  echo("nut tolerance = ", tol);
  h = 4;
  w = 3;
  d_tol = tol * 2;
  dI = d_puller + d_tol;
  dO = w*2 + dI;

  hC = h > 2*pitch ?  h : 2*pitch;

  difference() {
    cylinder(d=dO, h=hC);
    translate([0,0,-0.01]) metric_thread(
      diameter    = dI,
      length      = hC+0.02,
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
    cylinder(d=w, h=hC * 0.75);
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
  h_total   = d_pulley + 10;
  h_threads = 16;
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

    dn = sqrt(pow(d_puller,2)*2);
    echo(dn=dn);

    translate([-dn/2,-(w_pulley + 1)/2,-1]) 
      cube([dn, w_pulley + 1, d_pulley + 2]);

    // axel holes
    translate([0,0,d_pulley/2])
      rotate([90,0,0])
        translate([0,0,-(d_puller + 2)/2])
          cylinder(d=w_pulley_axel_hole, h=d_puller + 2);

    // square notches
    translate([0,0,-4])
      base_pillars(cutouts = true);

  }

}

module base_pillars(cutouts=false, height=d_pulley + 10 + 2) {
  tol = 0.5;
  lS  = cutouts ? 5.9 : 5.9 + tol;
  for (i=[0:3]) {
    rotate(i*90)
    translate([lS,lS,-1])
    cube([d_puller, d_puller, height]);
  }
}

module case () {
  h_case = 24;
  w_flanges = 4;
  d_case = d_puller + w_flanges * 2;
  w_case = w_extrusion + w_flanges * 2;
  w_channel = (5.9 + 0.5) * 2;
  h_channel = h_case - w_flanges;

  translate([0,0,- w_flanges])
  difference() {
    hull() {
      translate([0,0,w_flanges])
      cylinder(d=d_case, h=h_case + w_flanges);
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


case();
puller(false);
translate([0,0,28.2]) nut();
// 
// nut();
// translate([30,0,0]) test_thread();
