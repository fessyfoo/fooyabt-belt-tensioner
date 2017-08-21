use <threads.scad>;

$fs=0.1;
$fa=3;

// 4.6 pully puller wall
// 10.8 pully gap
// 4.3 pully puller nub
// 5.5 hole for pully bolt

d_pulley           = 22;
d_pulley_bolt_hold = 5.5;
w_pulley           = 11;
w_extrusion        = 20;
pitch              = 2;
groove             = false;
thread_size        = pitch * 1.0;

dn = sqrt(pow(20,2)*2);
echo(dn=dn);

function hyp(a,b) = sqrt(pow(a,2) + pow(b,2));

module nut(tol=0.75) {
  echo("nut tolerance = ", tol);
  h = 4;
  w = 3;
  d_tol = tol * 2;
  dI = w_extrusion + d_tol;
  dO = w*2 + dI;

  hC = h > 2*pitch ?  h : 2*pitch;

  difference() {
    cylinder(d=dO, h=hC);
    translate([0,0,-0.01]) metric_thread(
      groove      = groove,
      thread_size = thread_size,
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
  wC = w_extrusion / 2;
  translate([-wC/2,-wC/2]) cube([wC, wC, h*2]);
  metric_thread(
    groove = groove,
    thread_size = thread_size,
    diameter=w_extrusion,
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
        cylinder(d=w_extrusion, h=h_total);
      } else {
        cylinder(d=w_extrusion, h=h_base);
        translate([0,0,h_base]) metric_thread(
          groove      = groove,
          thread_size = thread_size,
          diameter    = w_extrusion,
          length      = h_threads,
          internal    = false,
          pitch       = pitch,
          leadin      = 1,
          leadinfac   = 2
        );
      }
    }

    translate([-dn/2,-(w_pulley + 1)/2,-1]) 
      cube([dn, w_pulley + 1, d_pulley + 2]);

    translate([0,0,d_pulley/2])
    rotate([90,0,0])
    translate([0,0,-(w_extrusion + 2)/2])
    cylinder(d=d_pulley_bolt_hold, h=w_extrusion + 2);

    translate([0,0,-4])
    base_pillars(cutouts = true);

    // for (i=[0:3]) {
    //   rotate(i*90)
    //   translate([5.9,5.9,-1])
    //   cube([w_extrusion, w_extrusion, d_pulley+10 + 2]);
    // }

  }

}

module base_pillars(cutouts=false) {
  tol = 0.5;
  lS  = cutouts ? 5.9 : 5.9 + tol;
  for (i=[0:3]) {
    rotate(i*90)
    translate([lS,lS,-1])
    cube([w_extrusion, w_extrusion, d_pulley+10 + 2]);
  }
}

module thread_inverse(h=20) {
  difference() {
    cylinder(d=w_extrusion * 1.25, h = h);
    translate([0,0,-1]) metric_thread(diameter=w_extrusion,length=h+2, internal=false);
  }
}

// translate([-30,30]) puller();
// translate([30,30,0]) nut();

// translate([30,0,0]) nut();
// test_thread();

module test_3_size_nuts () {
  for(i = [0:2]) { 
    translate([i * 35,0,0]) scale(1 + i * .05) nut();
    echo ("blah: ", 1 + i *.05);
  }
}


module case () {
  h_case = 28;
  w_flanges = 4;
  d_case = w_extrusion + w_flanges * 2;
  translate([0,0,h_case - 5])
  difference() {
    cylinder(d=d_case, h=5);
    translate([0,0,-0.1]) cylinder(d=w_extrusion + 1, h=10+0.2);
  }

  intersection() {
    cylinder(d=d_case, h=h_case);
    base_pillars();
  }

  translate([0,0,-w_flanges*2])
    difference() {
      hull() {
        translate([0,0,w_flanges]) cylinder(d=d_case, h=w_flanges);
        translate([0,0,w_flanges/2])
        cube([d_case, d_case, w_flanges], center=true);
      }
      translate([0,0,w_flanges/2])
      cube([w_extrusion + 0.5, w_extrusion + 0.5, w_flanges + 1], center=true);
      for (i=[0:180:360]) {
        rotate(i)
        translate([5.9,-(w_pulley+1)/2,-1])
          cube([20, w_pulley + 1, 20]);
      }
    }
}

case();
puller(false);
translate([0,0,28.2]) nut();

// nut();
// translate([30,0,0]) test_thread();
