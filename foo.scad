use <threads.scad>;

$fs=0.1;
$fa=1;

// TODO
// - flange for attaching t-nuts
// - 2040 case.

range              = 15;    // range of movement in mm
d_pulley           = 22;    // diameter of pulley (including clearance)
w_pulley           = 12;    // width of pulley (including clearance)
d_pulley_axel_hole = 5.5;   // diameter of axel hole, including tolerance
d_pulley_nut_hole  = 10;    // hex hole to make clearence for pulley bolt
w_extrusion        = 20;    // width of extrusion
extrusion_tol      = 0.375; // tolerance for attachment to extrusion.
puller_tol         = 0.5;   // tolerance around outside of puller
puller_pillar_tol  = 0.375; // tolerance around slots of puller
thickness          = 4;     // height of ring, width of flanges, ...
pitch              = 2;     // distance between threads
h_nut              = 2*thickness; // later normalized to multiple of pitch
h_puller_top       = pitch * 2; // amount of threads beyond the top of case


d_puller_min = d_for_pulley_clearance(w_pulley, d_pulley, d_pulley_nut_hole);
// diameter of the puller.  if this is big enough the pulley can be pulled
// partly through the top and nut to make use of the range
d_puller = d_puller_min;

r_embed       = d_puller_min <= d_puller ?
  d_pulley / 2 - d_pulley_nut_hole / 2 - 1 :
  0;

h_erange      = range - r_embed > 0 ? range - r_embed : r_embed;

h_case        = d_pulley + h_erange + thickness*2;
h_puller_trim = thickness / 2;
h_puller      = d_pulley + h_erange + thickness + h_puller_top - h_puller_trim;
d_case        = d_puller + thickness * 2;


echo(
  h_case        = h_case,
  h_puller      = h_puller,
  d_puller      = d_puller,
  d_puller_min  = d_puller_min,
  h_nut         = h_nut,
  range         = range,
  h_erange      = h_erange,
  r_embed       = r_embed,
  h_puller_trim = h_puller_trim,
  h_puller_top  = h_puller_top
);

function d_for_pulley_clearance(w_pulley, d_pulley, d_pulley_nut_hole) =
  let(
    c1 = d_pulley/2,
    a1 = d_pulley_nut_hole/2,
    b1 = sqrt(pow(c1,2) - pow(a1,2)),
    a2 = b1,
    b2 = w_pulley / 2,
    c2 = sqrt(pow(a2,2) + pow(b2,2))
  )
  ceil(c2 * 2) + 1 ;


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
  h_threads = range + thickness + h_puller_top;
  h_base    = h_puller - h_threads;

  difference() {
    union () {
      cylinder(d=d_puller, h=h_base);
      translate([0,0,h_base]) {
        if (fast) {
          color([0.5,0,0]) cylinder(d=d_puller, h=h_threads);
        } else {
          metric_thread(
            diameter    = d_puller,
            length      = h_threads,
            internal    = false,
            pitch       = pitch,
            leadin      = 1,
            leadinfac   = 2
          );
        }
      }
    }

    dn = d_puller + 0.2;
    // space for pulley
    translate([-dn/2,-w_pulley/2 -0.01 ,-1])
      cube([dn, w_pulley + 0.02, d_pulley + 2]);

    translate_z(d_pulley/2 - h_puller_trim) {

      // axel holes
      rotate([90,0,0])
        translate([0,0,-(d_puller + 2)/2])
          cylinder(d=d_pulley_axel_hole, h=d_puller + 2);

      // hex cutouts, keep stock size bolt fitting.
      difference() {
        rotate([90,90,0])
          translate_z(-(d_puller + 2)/2)
            cylinder($fn = 6, d=d_pulley_nut_hole, h=d_puller + 2);
        cube([10,w_extrusion,10], center=true);
      }
    }

    // square notches
    translate_z(-h_puller_top)
      base_pillars(cutouts = true);

    arch_cutout();

  }


}

module rotate_dup(a) {
  rotate(180) children();
  children();
}

module mirror_pillars() {
  mirror([1,0,0]) children();
  mirror([0,1,0]) children();
  rotate(180)     children();
  mirror([0,0,0]) children();
}

module base_pillars(
  cutouts = false,
  height  = h_puller,
  tol     = puller_pillar_tol
) {
  t   = cutouts ? 0 : tol;
  lS  = w_pulley / 2 + t;

  difference() {
    mirror_pillars()
      translate([lS,lS - tol,0])
        cube([d_puller, d_puller, height]);

    rotate_dup(180) {
      translate([-lS-thickness/2,lS + thickness/2 -2*t, -.1])
        cube([(lS+thickness/2)*2, d_puller, height + .2]);
    }
  }
}

module case() {
  case2();
}


module arch_cutout() {
  w = w_pulley + thickness + puller_pillar_tol * 2;
  translate_z(-0.01)
  resize([w, d_case + 2, w/2 ])
  arch();
}

module case_cutouts(
  w_flanges = thickness,
) {
  h_channel = h_case - thickness * 3 + thickness/2 ;

  // channel closed side
    translate_z( h_case - h_channel/2 - thickness)
    difference() {
      cube([w_pulley, d_case + 2, h_channel], center=true);
      translate_z(-h_channel/2)
        resize([w_pulley , d_case + 2, w_pulley/2])
          arch();
    }


  // channel open side.
  translate_z(h_case/2 - thickness)
    cube([d_case + 2, w_pulley, h_case], center=true);

  // 20x20 cutout
  translate([0,0,(w_flanges+1)/2 - .98]) // not sure why i needed this .98
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
      cylinder(d=d_puller + puller_tol*2, h = h_case + w_flanges * 2 + 2);
      translate([0,0,-1])
        base_pillars(height = h_case + w_flanges * 2 + 4);
        arch_cutout();
    }
}

module case1 () {
  w_flanges = thickness;
  h_case = h_case;
  w_case = w_extrusion + w_flanges * 2;

  difference() {
    hull() {
      cylinder(d=d_case, h=h_case);
      translate([0,0,w_flanges/2])
        cube([w_case, w_case, w_flanges], center=true);
    }

    case_cutouts(
      w_flanges     = w_flanges,
      extrusion_tol = extrusion_tol
    );

  }

}

module case2 () {
  w_flanges     = thickness;
  h_case        = h_case;
  w_case        = w_extrusion + w_flanges * 2;
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
      w_flanges     = w_flanges,
      extrusion_tol = extrusion_tol
    );



  }

  translate([0,-10 - extrusion_tol,0])
    vslot_supported(height=w_flanges, length=6+extrusion_tol, tol=extrusion_tol);
  translate([0,10 + extrusion_tol,0]) rotate(180)
    vslot_supported(height=w_flanges, length=6+extrusion_tol, tol=extrusion_tol);

}

module assembly (fast=false, nut=true) {
  case2();
  translate_z(h_puller_trim + h_puller_top + 0.2) puller(fast=fast);
  if (nut) { translate_z(h_case + 0.4 ) nut(); }
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
  rotate(120) translate([offset,0,0]) print_case();
  rotate(240) translate([offset,0,0]) print_puller();
}

module print_case() {
  flip(h_case) case();
}
module print_puller() {
  flip(h_puller) puller();
}

module display(fast=false) {
    translate([-67.5,0,0]) {
    rotate(45) assembly(fast=fast);
    translate([45,0,0]) rotate(45) case2();
    translate([90,0,0]) rotate(45) puller(fast=fast);
    translate([135,0,0]) nut();
  }
}

module test_hex_nut_hole() {
  slice = d_pulley - thickness*2;
  rotate([90,0,0])
  translate([0,0,-slice/2])
    intersection() {
      translate([-d_pulley/2,-0.1,0])
        cube([d_pulley, d_pulley, slice]);
      translate([0,-w_pulley/2,0]) puller(fast=true);
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

module test_base_pillars() {
  #base_pillars(cutouts=true);
  base_pillars(cutouts=false);
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

module arch() {
  rotate([0,90,90])
    translate([-1,0,0])
    difference() {
      translate([0.5,0,0])
        cube([1,2,1], center=true);
      translate([-0.01,0,0])
        cylinder(h=2, center=true);
    }
}

module test_case_bottom_inside() {
  difference() {
    test_2case();
    translate_z(60) cube(80, center=true);
  }
}

display();
