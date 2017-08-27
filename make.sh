#!/bin/sh -e

# this begs to be a makefile of some sort
# but banging this because it's quick and I'm slow at make. 

# TODO find openscad.  allow override.
openscad="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"

scad="fooyabt"

trap 'rm -f "$tmp_scad"' EXIT

bail() { 
  echo "$@"
  exit 1;
}

tmp_scad=".$scad.$$.scad"

cp "$scad.scad" "$tmp_scad"

out="${scad}_nut.stl"
echo "Making $out"
"$openscad" "$tmp_scad" -o "$out" -D object="3"

for range in 10 15 20
do
  for object in 0 1 2
  do
    case "$object" in
      0) name="plate";;
      1) name="case";;
      2) name="puller";;
      *) bail "huh? read source";;
    esac

    out="${scad}_r${range}_${name}.stl"

    echo "Making $out"
    "$openscad" "$tmp_scad" -o "$out" -D range="$range" -D object="$object"

  done
done


