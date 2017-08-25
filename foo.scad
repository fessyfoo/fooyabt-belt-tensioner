use <threads.scad>;

$fs=0.1;
$fa=3;


// TODO
// -  support for bridging on case.
// - flange on pully for lateral support.
// - flange for attaching t-nuts
// - 2040 case.
// - unify alternate case style dimension variables.

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
puller_pillar_tol  = 0.375;
h_t_nut_flange     = 10;
thickness          = 4;
pitch              = 2;

h_case   = range + d_pulley + thickness * 2;
h_nut    = thickness > 2*pitch ? ceil(thickness/pitch)*pitch : 2*pitch;
h_puller = d_pulley + range + h_nut;

function hyp(a,b) = sqrt(pow(a,2) + pow(b,2));

module translate_z (h) {
  translate([0,0,h]) children();
}

module nut() {
  nut2();
}


function h_nut(h_nut, pitch) = 
  h_nut > 2*pitch ? ceil(h_nut/pitch)*pitch : 2*pitch;

module nut1(tol=0.75, h_nut = h_nut, pitch = pitch) {
  h  = h_nut(h_nut, pitch);
  w  = thickness;
  dI = d_puller + tol*2;
  dO = w*2 + d_puller;
  c  = dO * PI;
  n  = floor(c/w/2);

  difference() {
    cylinder(d=dO, h=h);
    translate([0,0,-0.01]) metric_thread(
      diameter    = dI,
      length      = h+0.02,
      internal    = true,
      pitch       = pitch,
      leadin      = 0
    );
  }

  for (i=[0:360/n:360]) {
    rotate(i)
    translate([dO/2,0,0])
    cylinder(d=w, h=h * 0.75);
  }
}

module nut2(tol=0.75) {
  h   = h_nut(h_nut, pitch);
  w   = thickness;
  dI  = d_puller + tol * 2;
  dOb = w*2   + d_puller;
  dOt = w*1.5 + d_puller;

  c   = dOb * PI;
  d_nub = w * .75;
  n   = floor(c/d_nub/2);

  difference() {
    cylinder(d1=dOb, d2=dOt, h=h);
    translate([0,0,-0.01]) metric_thread(
      diameter    = dI,
      length      = h+0.02,
      internal    = true,
      pitch       = pitch,
      leadin      = 0
    );

    for (i=[0:360/n:360]) {
      rotate(i)
      translate([dOb/2,0,-0.1])
      cylinder(d=d_nub, h=h+0.2);
    }
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
  h_threads = h_total - (d_pulley + d_pulley_axel_hole) * 2/3 + thickness;
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

    translate_z(d_pulley/2 - thickness) {

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
    translate_z(-pitch * 1.5)
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

module case() {
  case2();
}


module case_cutouts(
  h_channel,
  w_channel,
  d_case,
  w_flanges,
  extrusion_tol,
) {
  // channel closed side
  rotate(90)
    translate([0,0, h_channel / 2 + w_flanges * 2])
      cube([d_case + 2, w_channel, h_channel], center=true);

  // channel open side.
  translate([0,0, (h_channel + w_flanges*2) / 2 - 1 ])
    cube([d_case + 2, w_channel, h_channel + w_flanges*2 + 2], center=true);

  // 20x20 cutout
  translate([0,0,(w_flanges+1)/2 - .98]) // not sure why i needed this.
    cube([
      w_extrusion + extrusion_tol,
      w_extrusion + extrusion_tol,
      w_flanges + 1
    ],
      center=true
    );

  // puller path
  translate([0,0,w_flanges*1.5 + 0.01])
    difference() {
      cylinder(d=d_puller_tol, h = h_case + w_flanges * 2 + 2);
      translate([0,0,-1])
        base_pillars(height = h_case + w_flanges * 2 + 4);
    }
}

module case1 () {
  w_flanges = thickness;
  h_case = h_case;
  d_case = d_puller + w_flanges * 2;
  w_case = w_extrusion + w_flanges * 2;
  w_channel = (5.9 + puller_pillar_tol) * 2;
  h_channel = h_case - w_flanges * 3;
  extrusion_tol = 0.375;

  difference() {
    hull() {
      cylinder(d=d_case, h=h_case);
      translate([0,0,w_flanges/2])
        cube([w_case, w_case, w_flanges], center=true);
    }

    case_cutouts(
      h_channel     = h_channel,
      w_channel     = w_channel,
      w_flanges     = w_flanges,
      d_case        = d_case,
      extrusion_tol = extrusion_tol
    );

  }

}

module case2 () {
  w_flanges     = thickness;
  h_case        = h_case;
  d_case        = d_puller + w_flanges * 2;
  w_case        = w_extrusion + w_flanges * 2;
  w_channel     = (5.9 + puller_pillar_tol) * 2;
  h_channel     = h_case - w_flanges * 3;
  extrusion_tol = 0.375;

  difference() {
    union() {
      hull() {
        translate_z(h_case - w_flanges)
          cylinder(d=d_case, h=w_flanges);
        translate_z(w_flanges/2 + w_flanges)
          cube([w_extrusion, w_case, w_flanges], center=true);
      }

      translate_z(w_flanges/2)
        cube([w_extrusion, w_case, w_flanges], center=true);
    }

    case_cutouts(
      h_channel     = h_channel,
      w_channel     = w_channel,
      w_flanges     = w_flanges,
      d_case        = d_case,
      extrusion_tol = extrusion_tol
    );



  }

  translate([0,-10 - extrusion_tol,0])
    vslot_supported(height=w_flanges, length=6+extrusion_tol, tol=extrusion_tol);
  translate([0,10 + extrusion_tol,0]) rotate(180)
    vslot_supported(height=w_flanges, length=6+extrusion_tol, tol=extrusion_tol);

}

module assembly () {
  case2();
  translate_z(thickness + pitch * 2.1) puller();
  translate_z(h_case + 0.4 ) nut();
}

module vslot(height=1, length = 6, tol=0.375) {

  l = length;
  t = tol;  // this technique could use some work.
  // points = [[0,0], [0,6], [3,6], [6,3], [6,2], [3,2], [5,0]];
  // points = [[0,0], [0,6], [3,6], [6,3], [6,2], [3,2], [3,0]];
  points = [[0,0], [0,l-t], [3-t,l-t], [6-t,l-t-3], [6-t,l+t-4], [3-t,l+t-4], [3-t,0]];

  linear_extrude(height)
    union() {
        mirror([1,0,0])
          polygon(points);
        polygon(points);
    }
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
  translate([45,0,0]) rotate(45) case2();
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

module vslot_supported(height=thickness, length=6, tol=0.375) {
  w_support = 12;
  union() {
    difference() {
      hull() {
        vslot(height=height, length=length, tol=tol);
        rotate(180)
        difference() {
          resize([w_support,length*2*0.65,height*1.5])
          cylinder();
          translate([-w_support/2,0,-1])
            cube([w_support,w_support,height*2 + 2]);
        }
      }
      translate_z(-(height+1)/2 + height)
        cube([20,20,height+1], center=true);
    }
    vslot(height=height, length=length, tol=tol);
  }
}

module test_bottom_case2() {
  flip () {
    difference() {
      translate_z(thickness/2 + thickness)
      cube([w_extrusion, w_extrusion +2*thickness, thickness], center=true);

      translate_z((thickness +2)/2 + thickness - 1 )
      cube([w_extrusion - thickness*2, w_extrusion, thickness + 2], center=true);
    }
    intersection() {
      case2();
      cube([40,40,thickness*2*2],center=true);
    }

  }
}

module test_2case() {
  translate([0,-20,0]) case1();
  translate([0,20,0])  case2();
}

module test_nuts() {
  translate([20,-20,0]) nut1(h_nut=thickness*2);
  translate([20,20,0])  nut2(h_nut=thickness*2);
  translate([-20,-20,0]) nut1();
  translate([-20,20,0])  nut2();
}

display();
