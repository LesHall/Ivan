// by Les Hall
// restarted Sun Aug 29 2015
// 



object();



module object()
{
    assembly();
    //rotate(180, [0, 1, 0]) stand();
    //mount();
    //post();
    //gear1();
    //gear2();
    //gear3();
    //plug();
    //wedge();
}



// skateboard bearings for wheel/tire support
// to relieve motor axle side force
bearing = [22, 8, 7];  // OD, ID, depth

// global parameters
thickness = 6;
play = 1;
clearance = 2;
explode = 0*(1 + cos(360*$t) )/2;
$fn = 64;

// printer parameters
printerSize = 152.4*[1, 1, 1];
skirtDistance = 8.0;

// fastener parameters
M3ScrewDiameter = 3.5;
M3ScrewCountersinkDiameter = 5.5;
M3ScrewHeadHeight = 3.0;

// NEMA 17 motor mount parameters
NEMA17BodySize = [42.4, 42.4, 40.2];
NEMA17M3ScrewSpacing = 31.0;
NEMA17PlateMountThickness = 2.0;
NEMA17PlateMountDiameter = 22.0;
NEMA17CountersinkDepth = 0.5;
NEMA17ShaftDiameter = 5.0;
NEMA17ShaftLength = 16.85;
NEMA17Plate = [NEMA17BodySize[0], NEMA17BodySize[1], 
    thickness];
NEMA17HeatSpacing = 10.0;

// planetary gear parameters
circPitch = 8;
height = bearing[2] + M3ScrewHeadHeight;
teeth1 = 12;
teeth2 = 18;
tMax = 4;
offset = 1.25;
boreDiameter = bearing[1];

// robot arm parameters
segmentAngle = 45;
numSegments = 3;
standHeight = NEMA17BodySize[2];
cutSize = 0.5;
cutOffset = 0.5;
theta = [0, .25, .25] * 90 * cos(360*$t) + [0, 0, 0];



include <MCAD/involute_gears.scad>

function pitch(mm) = mm * 180 / PI;
function radius(cp, t) = cp * t / (2*PI);
function teeth(cp, r) = 2*PI * r / cp;



radius1 = radius(circPitch, teeth1);
radius2 = radius(circPitch, teeth2);
distance12 = radius1 + radius2;
radius3 = radius1 + 2*radius2;
teeth3 = teeth(circPitch, radius3);
outerDiameter = ceil(2*radius3 + 2*circPitch);
H = height + clearance + bearing[2];
featureHoleSize = outerDiameter * cutSize;
featureHoleOffset = outerDiameter * cutOffset;



echo("outerDiameter = ", outerDiameter);
echo("teeth3 = ", teeth3);
echo("gear ratio = ", teeth3/teeth1);



// the whole thing (not printable)
module assembly()
{
    translate([0, 0, NEMA17BodySize[2]+thickness])
    positioned_segment(numSegments);
}



module positioned_segment(k)
{
    segment(k);
    
    if (k > 1)
    translate([0, 0, H])
    rotate(theta[k-1])
    translate([outerDiameter/2, 0, 0])
    rotate(segmentAngle, [0, 1, 0])
    translate([-outerDiameter/2, 0, 0])
    translate([0, 0, thickness])
    positioned_segment(k-1);
}



module segment(k)
{
    // the stand that Ivan's Segments rest upon
    color("Red")
    if(k == numSegments)
    translate([0, 0, -standHeight-thickness])
    stand();
    
    // the mount on which all the gears are attached
    color("Red")
    translate([0, 0, -thickness/2])
    mount();


    // 4 posts for the planet gears
    translate([0, 0, 30*explode])
    for(t = [0:tMax-1])
    {
        rotate(360 * t/tMax, [0, 0, 1])
        translate([distance12 + offset, 0, 0])
        post();
    }
    
    // sun gears
    translate([0, 0, 60*explode])
    color("Gold")
    rotate(360/teeth1/2)
    gear1();

    // planet gears
    translate([0, 0, 60*explode])
    color("Black")
    for(t=[0:tMax-1])
    rotate(360*t/tMax)
    translate([distance12+offset, 0, 0])
    rotate(360*(t+1)/tMax*teeth1/teeth2)
    gear2();

    rotate(theta[k-1])
    {
        // outer ring gear
        translate([0, 0, 90*explode])
        color("Green")
        rotate(360*teeth3/tMax/2)
        translate([0, 0, height+clearance])
        rotate(180, [0, 1, 0])
        gear3();

        // angular adapter
        color("Red")
        if (k > 1)
        translate([0, 0, H])
        wedge();
    }
    
    // plug holding gear3 bearing
    translate([0, 0, 90*explode])
    color("Green")
    translate([0, 0, height+M3ScrewHeadHeight+clearance])
    plug();
    
    // four bearings to spin the planet gears
    color("Silver")
    translate([0, 0, 60*explode])
    for (t = [0:tMax-1])
    {
        rotate(360*t/tMax)
        translate([distance12+offset, 0, 0])
        bearing();
    }
    
    // the NEMA17 motor
    color("Silver")
    translate([0, 0, -NEMA17Plate[2]])
    motor();
}



module mount()
{
    difference()
    {
        // main shape
        cylinder(h = thickness, 
            d = outerDiameter, 
            center=true);
        
        // holes for motor
        motor_mount_holes();
        
        // screw holes
        for (t = [0:tMax-1])
        {
            // screw holes for planet gears
            rotate(360 * t/tMax, [0, 0, 1])
            translate([distance12+offset, 0, 0])
            translate([0, 0, thickness/2])
            rotate(180, [0, 1, 0])
            screw_hole(countersink = 2.25);
            
            // screw holes for mount
            rotate(360 * (t + 1/2)/tMax, [0, 0, 1])
            translate([distance12+offset+radius2/2, 0, 0])
            translate([0, 0, -thickness/2])
            screw_hole(countersink = 2.25);
        }
        
        // ridges underneath to prevent lifting
        numRings = 7;
        for (t = [0:numRings-1])
        {
            if ( (t != 2) && (t != 4) )
            translate([0, 0, -thickness/2])
            rotate_extrude()
            translate([
                outerDiameter/2 - thickness*(t+1), 0, 0])
            circle(d = thickness/2);
        }
    }
}



module post()
{
    difference()
    {
        cylinder(d=boreDiameter, h=height);
        
        translate([0, 0, height])
        screw_hole(countersink = 0);
    }
}



module bearing()
{
    difference()
    {
        cylinder(h=bearing[2], d=bearing[0]);

        cylinder(h=bearing[2]+1, d=bearing[1]);
    }
}



// sun gear
module gear1()
{
	gear (number_of_teeth = teeth1, circular_pitch=pitch(circPitch), bore_diameter = NEMA17ShaftDiameter, hub_diamete = 0, rim_width = 0, gear_thickness = height, rim_thickness = height, hub_thickness = height, circles=0);
}


// planet gears
module gear2()
{
	gear (number_of_teeth = teeth2, circular_pitch=pitch(circPitch), bore_diameter = bearing[0], hub_diameter = 0, rim_width = 0, gear_thickness = height, rim_thickness = height, hub_thickness = height, circles=0);
}


// annular gear
module gear3()
{
    // the gear teeth
    difference()
    {
        union()
        {
            difference()
            {
                // main shape
                translate([0, 0, -bearing[2]])
                cylinder(d=outerDiameter, h=H);
                
                // bearing hole
                translate([0, 0, -bearing[2]-1])
                cylinder(h = bearing[2]+2, d = bearing[0]);
                
                // rotary features
                translate([0, 0, -bearing[2]-1])
                for(t = [0:tMax-1])
                {
                    // four holes to view gears()
                    rotate(360 * t/tMax)
                    translate([featureHoleOffset, 0, 0])
                    cylinder(h = bearing[2]+2, 
                        d = featureHoleSize);
                    
                    rotate(360 * (t+1/2)/tMax)
                    translate([distance12+offset+radius2/2, 0, 0])
                    cylinder(h = bearing[2]+2, 
                        d = M3ScrewDiameter);
                }
            }
            
            // outer rim for upper gear cut printability
            translate([0, 0, -bearing[2]])
            difference()
            {
                cylinder(h = bearing[2]+clearance, 
                    d = outerDiameter);
                
                translate([0, 0, -1])
                cylinder(h = bearing[2]+clearance+2, 
                    d = 1.25*outerDiameter - radius3);
            }
        }
        
        // subtract off a gear
        gear (number_of_teeth = teeth3, circular_pitch=pitch(circPitch*1.05), bore_diameter = 0, hub_diameter = 2*boreDiameter, rim_width = boreDiameter/4, gear_thickness = H+1, rim_thickness = H+1, hub_thickness = H+1, circles=0);
    }
}



module plug()
{
    difference()
    {
        cylinder(d = bearing[1], h = bearing[2]);
        
        translate([0, 0, bearing[2]-1])
        cylinder(h = bearing[2]+2, d = NEMA17ShaftDiameter);
    }
}



// NEMA 17 motor
module motor()
{
    translate([0, 0, -NEMA17BodySize[2]/2])
    {
        // body
        cube(NEMA17BodySize, center = true);
        
        // plate mount
        translate([0, 0, NEMA17BodySize[2]/2])
        cylinder(h = NEMA17PlateMountThickness, 
            d = NEMA17PlateMountDiameter);
        
        // shaft
        translate([0, 0, 
            NEMA17PlateMountThickness+NEMA17BodySize[2]/2])
        cylinder(h = NEMA17ShaftLength, 
            d = NEMA17ShaftDiameter);
    }
}



module motor_mount()
{
    difference()
    {
        cube(NEMA17Plate, center=true);
        
        motor_mount_holes();
    }
}



// plate for mounting the motor
module motor_mount_holes()
{
    SS = NEMA17M3ScrewSpacing;
    
    // subtract off the M3 screw holes
    translate([0, 0, NEMA17Plate[2]/2])
    for(x=[-1:2:1], y=[-1:2:1])
    {
        translate([SS/2*x, SS/2*y, -thickness])
        screw_hole(countersink = 2.25);
    }
    
    // subtract off the bearing hole
    translate([0, 0, NEMA17Plate[2]/2+1])
    rotate(180, [0, 1, 0])
    cylinder(h = NEMA17Plate[2]+2, 
        d = NEMA17PlateMountDiameter);
}



module screw_hole(countersink = 2.25)
{
    SD = M3ScrewDiameter;
    SCD = M3ScrewCountersinkDiameter;

    translate([0, 0, thickness])
    union()
    {
        // the shafts of the screws
        rotate(180, [0, 1, 0])
        cylinder(h = 2*height, 
            d = SD);
        
        // the recesses to countersink the screws
        rotate(180, [0, 1, 0])
        cylinder(h = countersink, 
            d = SCD);
    }
}



module wedge()
{
    difference()
    {
        translate([outerDiameter/2, 0, 0])
        difference()
        {
            intersection()
            {
                // main torus shape
                torus(outerDiameter, outerDiameter/2);
                
                // confining cubes
                translate(outerDiameter*[-1/2, 0, 1/2])
                cube(outerDiameter, center = true);
                
                // confining cubes
                rotate(segmentAngle-90, [0, 1, 0])
                translate(outerDiameter*[-1/2, 0, 1/2])
                cube(outerDiameter, center = true);
                
            }
            
            // outside cut
            torus(featureHoleSize, 
                outerDiameter/2 + featureHoleOffset);
            
            // inside cut
            translate([featureHoleOffse, 0, 0])
            sphere(d = featureHoleSize);
            
            // side cuts
            for (side = [-1:2:1])
            {
                translate([0, side * featureHoleOffset, 0])
                torus(featureHoleSize, outerDiameter/2);
            }
            
            // bearing cut
            torus(bearing[0], outerDiameter/2);
        }
        
        // centeral chamber cut
        translate([outerDiameter/2, 0, 0])
        rotate(segmentAngle, [0, 1, 0])
        translate([-outerDiameter/2, 0, 0])
        translate([0, 0, -NEMA17BodySize[2]/2])
        {
            // cube-ish hole for the motor
            cube(NEMA17BodySize, center=true);
            
            // exit hole for the wiring
            for (side = [0:1])
            {
                rotate(90*side)
                translate([0, 0, -NEMA17BodySize[2]/2])
                rotate(-90, [0, 1, 0])
                cylinder(h = outerDiameter, 
                    d = NEMA17BodySize[2]/2, 
                    center=true);
            }
        }
        
        // screw holes for planet gears
        for (t = [0:tMax-1], side = [0:1])
        {
            translate([side*outerDiameter/2, 0, 0])
            rotate(segmentAngle, [0, side, 0])
            translate([-side*outerDiameter/2, 0, 0])
            rotate(360* (t + 1/2)/tMax, [0, 0, 1])
            translate([distance12+offset+radius2/2, 0, 0])
            rotate(180, [0, side, 0])
            screw_hole(countersink = 0);
        }
    }
}



module torus(diameter, offset)
{
    rotate(90, [1, 0, 0])
    rotate_extrude()
    translate([offset, 0, 0])
    circle(d = diameter);
}



module stand()
{
    difference()
    {
        // main shape
        cylinder(h = standHeight, d = outerDiameter);
        
        // centeral chamber cut
        translate([0, 0, standHeight-NEMA17BodySize[2]/2])
        cube(NEMA17BodySize, center=true);
        
        // outer round cuts
        for (t = [0:tMax-1])
        {
            rotate(360 * t/tMax)
            translate([featureHoleOffset, 0, -1])
            cylinder(h = standHeight+2, 
                d = featureHoleSize);
        }
        
        // screw holes for planet gears
        for (t = [0:tMax-1], side = [0:1])
        {
            rotate(360* (t + 1/2)/tMax, [0, 0, 1])
            translate([distance12+offset+radius2/2, 0, 0])
            translate([0, 0, side*standHeight])
            screw_hole(countersink = 2.25);
        }
            
        // exit hole for the wiring
        for (side = [0:1])
        {
            rotate(90*side)
            rotate(-90, [0, 1, 0])
            cylinder(h = outerDiameter, 
                d = NEMA17BodySize[2]/2, 
                center=true);
        }
    }
}


