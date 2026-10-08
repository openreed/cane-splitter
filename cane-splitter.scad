// OpenReed 芦苇管三分／四分器，建模代码集中于一个文件 | Single-source cane splitter.
include <BOSL2/std.scad>
include <BOSL2/screws.scad>

// 圆弧精度按 reed-guillotine 统一设置；不使用固定圆周分段数覆盖它。
// Shared circular precision; $fn=0 keeps $fa/$fs effective.
// 圆弧分段角度设置 | Angular resolution setting for circles
$fa = 1;
// 圆弧分段长度设置 | Segment-length resolution setting for circles
$fs = 0.1;
// 使用角度与长度自动分段 | Use automatic angular/length tessellation
$fn = 0;
// 尺寸单位为毫米；芦苇从 +Z 进入，刃口朝 +Z | Millimetres; top-down feed.

/*[输出 | Output]*/
// 乐器：双簧管三等分，巴松四等分 | Oboe: three sectors; bassoon: four sectors
cfg_instrument = "oboe"; // [oboe,bassoon]
// 输出零件或查看方式 | Output part or inspection view
cfg_part = "exploded"; // [assembly,exploded,section,operation,body,locking_ring,palm_cap,coupon,connection_coupon,print_plate]
// 装配图中显示刀片和标准件 | Show blades and standard hardware in assembly views
cfg_show_hardware = true;

/*[基本参数 | Basic Parameters]*/
// 芦苇管外径；0 使用默认值：双簧管 10、巴松 25 mm | Cane OD; 0 selects 10 mm oboe / 25 mm bassoon
cfg_cane_diameter = 0;
// 顶盖上沿、主体底沿及掌压盖外沿的 45° 倒角宽度 | 45-degree outer-edge chamfer width on the lid, body base and palm cap
cfg_edge_chamfer = 1;

/*[刀片参数 | Blade Parameters]*/
// 完整 009RD 刀片长度，沿刃口方向 | Complete blade length along the cutting edge
cfg_blade_length = 39;
// 刀片总宽度，从刃口到刀背 | Overall blade width from edge to back
cfg_blade_width = 19.4;
// 刀片薄钢片厚度 | Thickness of the thin steel blade
cfg_blade_thickness = 0.23;
// 刀背总厚度，复用 reed-guillotine 的 0.23 + 0.30 mm | Total backing thickness: 0.23 + 0.30 mm
cfg_back_thickness = 0.53;
// 加厚刀背区域的宽度 | Width of the reinforced backing
cfg_back_width = 7;
// 两个短端圆底缺口的总深度 | Overall depth of each round-bottom end notch
cfg_notch_depth = 3.8;
// 侧缺口宽度，也是圆底直径 | End-notch width and rounded-root diameter
cfg_notch_width = 3.0;
// 缺口中心到刃口的距离 | Distance from the cutting edge to the notch centre
cfg_notch_from_edge = 9.6;

/*[公差 | Tolerances]*/
// 刀身槽增加的总宽度；每侧为此值的一半 | Added blade-slot width, half on each side
cfg_blade_slot_clearance = 0.16;
// 刀背槽增加的总宽度；每侧为此值的一半 | Added backing-slot width, half on each side
cfg_back_slot_clearance = 0.20;
// 保护盖内螺纹的径向间隙 | Radial clearance of the cap thread
cfg_thread_radial_clearance = 0.30;
// 保护盖内螺纹牙槽每侧的轴向间隙 | Axial clearance on each flank of the cap thread
cfg_thread_axial_clearance = 0.15;

/*[导向盖连接参数 | Guide Lid Connection Parameters]*/
// 积木式圆榫外径；中心同时容纳 M4 螺纹 | Round locating-stud diameter, with M4 thread at its centre
cfg_locator_diameter = 7;
// 圆榫突出主体顶面的高度 | Locating-stud height above the body seating face
cfg_locator_height = 2.5;
// 榫孔增加的直径间隙 | Added diameter clearance of each locating socket
cfg_locator_diameter_clearance = 0.30;
// 榫孔增加的深度间隙 | Added depth clearance of each locating socket
cfg_locator_depth_clearance = 0.30;
// M4 内螺纹的打印补偿量；BOSL2 实际直径增加 4 倍此值 | BOSL2 print slop; diameter increases by four times this value
cfg_m4_thread_slop = 0.04;

/*[Hidden]*/
// 检查项名称，留空时输出正常模型 | Diagnostic name; empty selects the normal model
cfg_check = "";
// 检查装刀路径时的竖直抬升量 | Vertical displacement for blade-insertion checks
cfg_insertion = 0;
// 检查保护盖旋开时的圈数 | Revolutions for cap-unscrewing checks
cfg_cap_turns = 0;

// 内部参数 | Internal Parameters
// 布尔运算切除体的越界量 | Overrun of Boolean cutters
eps = 0.02;
// 刀片数量与等分数量 | Blade and sector count
n = cfg_instrument == "oboe" ? 3 : 4;
// 实际采用的芦苇外径 | Effective cane outside diameter
cane_d = cfg_cane_diameter == 0 ? (n==3 ? 10 : 25) : cfg_cane_diameter;
// 支持的最小芦苇外径 | Minimum supported cane OD
cane_min = n==3 ? 9.5 : 23;
// 支持的最大芦苇外径 | Maximum supported cane OD
cane_max = n==3 ? 11.5 : 27;
// 刀片长度 | Blade length
L = cfg_blade_length;
// 刀片宽度 | Blade width
W = cfg_blade_width;
// 刀身厚度 | Blade thickness
T = cfg_blade_thickness;
// 刀背总厚度 | Total backing thickness
back_t = cfg_back_thickness;
// 加厚刀背区域宽度 | Reinforced backing width
back_w = cfg_back_width;
// 侧缺口总深度 | Overall end-notch depth
notch_d = cfg_notch_depth;
// 侧缺口宽度 | End-notch width
notch_w = cfg_notch_width;
// 缺口中心距刃口的距离 | Notch-centre distance from the edge
notch_v = cfg_notch_from_edge;
// 刃口内端距中心轴的距离 | Radius of the inner cutting-edge end
inner_r = 2.5;
// 中心短导向柱半径，与三／四条支撑筋相连 | Short central guide radius, joined to all fins
hub_r = 2.2;
// 刀背内端的高度基准 | Height datum at the inner back end
seat_z = 5;
// 刀座外壁厚度 | Body shell thickness
wall = 3;
// 刀座支撑筋厚度 | Blade-support fin thickness
fin_t = 3.2;
// 支撑筋相对刃口的径向退让 | Radial setback of the support behind the edge
edge_exposure = 0.8;
// 刀片相对竖直方向的倾角 | Blade inclination from vertical
a = asin((cane_max/2+1-inner_r)/L);
// 刃口内端高度 | Inner cutting-edge height
edge_inner_z = seat_z+W*sin(a);
// 支撑筋中心端的顶部高度 | Top height at the central end of each support fin
fin_root_z = edge_inner_z-0.8;
// 导向柱高于支撑筋根部的长度 | Guide projection above the support-fin roots
hub_projection = 6;
// 中心导向柱总高度 | Overall central guide height
hub_h = fin_root_z+hub_projection;
// 中心短柱顶部圆角半径 | Top-edge rounding radius of the short hub
hub_round = 0.6;
// 导向柱与支撑筋之间的平面内凹圆角半径 | Concave plan fillet between the hub and support fins
fin_root_round = 0.8;
// 刃口外端半径 | Outer cutting-edge radius
edge_outer_r = inner_r+L*sin(a);
// 刃口外端高度 | Outer cutting-edge height
edge_outer_z = edge_inner_z+L*cos(a);
// 刀背外端半径 | Outer backing radius
outer_back_r = edge_outer_r+W*cos(a);
// 刀座外壁半径，不含螺纹和台肩 | Body shell radius, excluding thread and shoulder
body_r = outer_back_r+3.5;
// 刀座总高度 | Body height
body_h = edge_outer_z+2;
// 底部出口半径 | Bottom exit radius
exit_r = cane_max/2+3;
// 导向圈中心孔半径 | Guide aperture radius
guide_r = (cane_d+1)/2;
// 橙色导向盖厚度，默认沉孔和榫孔之间保留 1.9 mm | Guide lid thickness; 1.9 mm floor between counterbore and socket
ring_h = 9;
// 导向盖固定螺丝及定位圆榫的分布半径 | Shared placement radius of lid screws and locating studs
ring_bolt_r = body_r-6;
// 导向盖固定座内端半圆的半径，也是连接墙的半宽 | Rounded mount-end radius and half-width of its connecting wall
ring_post_r = 4.5;
// 导向盖连接墙的外端，伸入主体侧壁中部 | Outer end of the lid mounting wall, embedded in the body shell
ring_wall_end = body_r-wall/2;
// ISO 4762 M4 螺丝的杆长 | ISO 4762 M4 screw length beneath the head
ring_screw_L = 12;
// M4 粗牙螺距 | M4 coarse thread pitch
ring_screw_pitch = 0.7;
// M4 螺丝头外径 | M4 socket-head diameter
ring_head_d = 7;
// M4 螺丝头高度 | M4 socket-head height
ring_head_h = 4;
// 橙色导向盖的螺丝通孔直径 | Lid screw clearance-hole diameter
ring_hole_d = 4.4;
// 螺丝头沉孔直径 | Screw-head counterbore diameter
ring_counterbore_d = ring_head_d+0.6;
// 螺丝头沉孔深度，使头部低于顶面 0.3 mm | Counterbore depth; head sits 0.3 mm below the lid top
ring_counterbore_depth = ring_head_h+0.3;
// 螺丝头的承压面相对主体顶面的高度 | Screw-head bearing plane above the body seating face
ring_head_seat = ring_h-ring_counterbore_depth;
// 主体内 M4 盲螺孔从圆榫顶部向下的深度 | M4 blind-hole depth measured down from the stud top
ring_thread_depth = 12;
// 标准螺丝参考模型的旋合相位，补偿 BOSL2 内外螺纹的半牙相位差 | Reference screw phase, accounting for BOSL2's half-pitch internal profile shift
ring_screw_spin = 360*((ring_head_seat-cfg_locator_height-eps/2+(ring_thread_depth-ring_screw_L)/2)/ring_screw_pitch-0.5);
// 定位圆榫直径 | Locating-stud diameter
locator_d = cfg_locator_diameter;
// 定位圆榫突出高度 | Locating-stud projection height
locator_h = cfg_locator_height;
// 定位圆榫顶部导入倒角高度 | Locating-stud lead-in chamfer height
locator_chamfer = 0.4;
// 刀片夹紧螺丝直径，采用 M2.5 | Blade clamp screw diameter: M2.5
clamp_d = 2.5;
// 刀片夹紧螺丝通孔直径 | Blade clamp clearance-hole diameter
clamp_hole_d = 2.8;
// ISO 4762 M2.5 螺丝的杆长 | ISO 4762 M2.5 screw length beneath the head
clamp_L = 10;
// M2.5 六角螺母对边尺寸 | M2.5 nut width across flats
clamp_nut_af = 5;
// M2.5 六角螺母厚度 | M2.5 nut thickness
clamp_nut_h = 2;
// 外端圆底缺口中心沿刃口的位置 | Position of the outer notch root along the edge
clamp_u = L-(notch_d-notch_w/2);
// 夹紧螺丝中心的径向与高度坐标 | Radial and height coordinates of the clamp screw
clamp_p = [inner_r+clamp_u*sin(a)+notch_v*cos(a),
           edge_inner_z+clamp_u*cos(a)-notch_v*sin(a)];
// 支撑筋外段的夹紧厚度，沿打印高度保持一致 | Constant thickness of the outer clamping web
clamp_span = 8;
// 螺孔中心到夹紧厚壁内缘的距离 | Screw-centre setback from the inner edge of the thick web
clamp_edge_margin = 3.8;
// 夹紧厚壁的内缘半径，避开苇片出口 | Inner radius of the clamping web, outside the cane exits
clamp_inner_r = clamp_p[0]-clamp_edge_margin;
// 单线右旋梯形螺纹的螺距 | Pitch of the single-start right-hand trapezoidal thread
thread_pitch = 3.6;
// 外螺纹径向牙高 | Radial height of the external thread
thread_depth = 1.0;
// 螺纹及其配合圆柱的统一分段数 | Shared tessellation of the thread and mating cylinders
thread_segments = circle_segments(body_r+thread_depth+cfg_thread_radial_clearance);
// 外螺纹起始高度 | Lower end of the external thread band
thread_start = body_h-10;
// 外螺纹终止高度 | Upper end of the external thread band
thread_end = body_h-2;
// 螺旋线零角度处的高度基准 | Helix height datum at zero angle
thread_phase = thread_start+thread_pitch/2;
// 内螺纹径向间隙 | Internal-thread radial clearance
thread_fit = cfg_thread_radial_clearance;
// 内螺纹每侧轴向间隙 | Internal-thread axial clearance per flank
thread_zfit = cfg_thread_axial_clearance;
// 旋紧保护盖的开口面高度 | Open-face height of the seated cap
cap_bottom = thread_start-0.5;
// 保护盖内侧掌面高度 | Inside palm-face height of the cap
cap_ceiling = body_h+ring_h+2;
// 保护盖外侧掌面高度 | Outside palm-face height of the cap
cap_top = cap_ceiling+4;
// 保护盖总高度 | Overall cap height
cap_h = cap_top-cap_bottom;
// 保护盖外半径 | Outside cap radius
cap_r = body_r+thread_depth+thread_fit+2.5;
// 顶盖沉孔外侧上沿的最小保留宽度 | Minimum retained lid lip outside a counterbore
edge_min_lip = 0.4;
// 主体底部及掌压盖开口的最小保留壁厚 | Minimum retained wall at the body base and palm-cap opening
edge_min_wall = 1.2;
// 倒角上限按实际几何计算，并同时保留壁厚与零件高度 | Chamfer limit derived from actual wall clearances and part heights
edge_chamfer_max = min(body_r-ring_bolt_r-ring_counterbore_d/2-edge_min_lip,
    wall-edge_min_wall,
    cap_r-(body_r+thread_depth+thread_fit+0.1)-edge_min_wall,
    ring_h/2,cap_h/2);
// 刀座实体合并后统一裁平顶面的越界量 | Top overrun before one common trimming cut
top_join = 0.3;
// 自动分段符合 $fa/$fs；手工生成的螺旋网格采用同一精度 | Matching tessellation for manually generated helices
function circle_segments(r) = ceil(max(5,min(360/$fa,2*PI*r/$fs)));

// u 沿刃口向外、向上；v 从刃口向刀背向外、向下。
// u runs outward/up along the edge; v runs outward/down toward the back.
function p(u,v)=[inner_r+u*sin(a)+v*cos(a),edge_inner_z+u*cos(a)-v*sin(a)];
function rect(u0,u1,v0,v1)=[p(u0,v0),p(u1,v0),p(u1,v1),p(u0,v1)];
module xz_prism(points,t) {
    translate([0,t/2,0]) rotate([90,0,0]) linear_extrude(height=t) polygon(points);
}
module radial(count=n,offset=0) {
    for(i=[0:count-1]) rotate([0,0,offset+i*360/count]) children();
}
module hex(af,h) { linear_extrude(height=h) polygon([for(t=[0:60:300]) af/(2*cos(30))*[cos(t),sin(t)]]); }
module outer_edge_chamfer(r,z,upper=false) {
    // 旋转闭合三角轮廓，仅切外缘；切除体向外及端面越界。
    // Closed revolved cutter with overrun, limited to the outside edge.
    c=cfg_edge_chamfer;
    if(c>0) translate([0,0,z]) rotate_extrude() polygon(upper ?
        [[r-c-eps,eps],[r+eps,eps],[r+eps,-c-eps]] :
        [[r-c-eps,-eps],[r+eps,-eps],[r+eps,c+eps]]);
}
module blade_frame() {
    multmatrix([[sin(a),0,cos(a),inner_r],[0,1,0,0],
                [cos(a),0,-sin(a),edge_inner_z],[0,0,0,1]]) children();
}
module blade_metal() {
    blade_frame() difference() {
        // 刀身、刃口和加厚刀背一次挤出，避免端面的共面重叠。
        // Extrude one stepped section including the finite 0.01 mm edge tip.
        rotate([0,90,0]) linear_extrude(height=L)
            polygon([[0,-0.005],[-0.7,-T/2],[-(W-back_w),-T/2],
                [-(W-back_w),-back_t/2],[-W,-back_t/2],[-W,back_t/2],
                [-(W-back_w),back_t/2],[-(W-back_w),T/2],[-0.7,T/2],[0,0.005]]);
        for(side=[0,1]) {
            base=notch_d-notch_w/2;
            translate([side==0 ? -eps : L-base,-back_t,notch_v-notch_w/2])
                cube([base+eps,2*back_t,notch_w]);
            translate([side==0 ? base : L-base,back_t,notch_v]) rotate([90,0,0])
                cylinder(r=notch_w/2,h=2*back_t);
        }
        translate([L/2,back_t,7]) rotate([90,0,0]) cylinder(d=2.1,h=2*back_t);
    }
}
module blade_visual() {
    // Disjoint volumes with a shared boundary, not a colored overlapping skin.
    color([0.72,0.75,0.78]) render(convexity=20) difference() {
        blade_metal(); xz_prism(rect(-eps,L+eps,-eps,0.7),back_t+1);
    }
    color([0.96,0.32,0.12]) render(convexity=20) intersection() {
        blade_metal(); xz_prism(rect(-eps,L+eps,-eps,0.7),back_t+1);
    }
}
module blade_channel() {
    // Sweep straight UP: blades install vertically, without thinning the rim.
    // Thin face and reinforced back have separate, closed-sided guides.
    for(k=[0:1]) hull() {
        v0=k==0 ? -0.10 : W-back_w-0.10;
        t=k==0 ? T+cfg_blade_slot_clearance : back_t+cfg_back_slot_clearance;
        // 刀背切除体多越界 0.05 mm，避免两种刀槽的端面重合。
        // Stagger cutter ends by 0.05 mm while preserving slot widths.
        overrun=k==0 ? 0.15 : 0.20;
        xz_prism(rect(-overrun,L+overrun,v0,W+overrun),t);
        translate([0,0,body_h+L]) xz_prism(rect(-overrun,L+overrun,v0,W+overrun),t);
    }
}
module support_fins() {
    // 先统一柱根与筋条的平面轮廓，内端伸至轴心后整体加内凹圆角。
    // Blend one hub/spoke footprint; the spoke ends are buried at the axis.
    intersection() {
        linear_extrude(height=body_h+top_join) round2d(ir=fin_root_round) union() {
            circle(r=hub_r);
            radial() translate([0,-fin_t/2]) square([body_r-wall/2,fin_t]);
        }
        // 较宽的高度裁剪体只限制顶部斜面；实际筋宽由上面的轮廓确定。
        // The wide mask sets sloping top heights; the footprint sets fin width.
        radial() xz_prism([[0,0],[body_r-wall/2,0],[body_r-wall/2,body_h+top_join],
            [edge_outer_r+edge_exposure,body_h+top_join],
            [edge_outer_r+edge_exposure,edge_outer_z],
            [inner_r+edge_exposure,edge_inner_z],[0,fin_root_z]],fin_t+2*fin_root_round);
    }
    // 螺孔直接位于从底面到顶面的整条厚壁内，不再添加横向圆柱凸耳。
    // The screw sits in a straight web supported from the bed to the top.
    radial() xz_prism([[clamp_inner_r,0],[body_r-wall/2,0],
        [body_r-wall/2,body_h+top_join],[clamp_inner_r,body_h+top_join]],clamp_span);
}
module clamp_cutouts() {
    translate([clamp_p[0],clamp_span/2+eps,clamp_p[1]]) rotate([90,0,0])
        cylinder(d=clamp_hole_d,h=clamp_span+2*eps);
    // Nut is loaded from the +Y face with ring removed; pocket keeps it still.
    translate([clamp_p[0],clamp_span/2+eps,clamp_p[1]]) rotate([90,0,0])
        hex(clamp_nut_af+0.25,clamp_nut_h+0.15+eps);
}

module guide_hub() {
    // 单个旋转实体生成圆头短柱，避免圆柱与球面相切的布尔接缝。
    // One revolved solid makes the rounded hub without tangent Boolean seams.
    arc_steps=ceil(circle_segments(hub_round)/4);
    rotate_extrude() polygon(concat([[0,0],[hub_r,0]],
        [for(i=[0:arc_steps]) let(t=90*i/arc_steps)
            [hub_r-hub_round+hub_round*cos(t),hub_h-hub_round+hub_round*sin(t)]],
        [[0,hub_h]]));
}

// 闭合的三角面螺纹扫掠体，所有面朝外 | Closed thread sweep with outward faces.
module helix(root_r,depth,zlo,zhi,radial_fit=0,axial_fit=0) {
    steps=thread_segments;
    first=floor((zlo-thread_phase)/thread_pitch)-1;
    last=ceil((zhi-thread_phase)/thread_pitch)+1;
    segments=(last-first)*steps;
    section=[[root_r-0.12+radial_fit,-1.35-axial_fit],
             [root_r+depth+radial_fit,-0.25-axial_fit],
             [root_r+depth+radial_fit,0.25+axial_fit],
             [root_r-0.12+radial_fit,1.35+axial_fit]];
    vertices=[for(i=[0:segments]) for(j=[0:3])
        let(theta=360*(first+i/steps),s=section[j])
            [s[0]*cos(theta+0.73),s[0]*sin(theta+0.73),thread_phase+thread_pitch*theta/360+s[1]]];
    sides=[for(i=[0:segments-1]) for(j=[0:3]) for(k=[0:1])
        let(b=4*i,c=4*(i+1),q=(j+1)%4)
            k==0 ? [b+j,c+q,c+j] : [b+j,b+q,c+q]];
    end=4*segments;
    // 从外部看，OpenSCAD 的面顶点按顺时针排列 | Clockwise from outside.
    polyhedron(points=vertices,faces=concat([[0,2,1],[0,3,2]],sides,
        [[end+2,end,end+1],[end+3,end,end+2]]),convexity=30);
}
module external_thread() {
    intersection() {
        helix(body_r,thread_depth,thread_start,thread_end);
        union() {
            translate([0,0,thread_start]) cylinder(r1=body_r+0.12,r2=body_r+thread_depth,h=0.9);
            translate([0,0,thread_start+0.9]) cylinder(r=body_r+thread_depth,h=thread_end-thread_start-1.8);
            translate([0,0,thread_end-0.9]) cylinder(r1=body_r+thread_depth,r2=body_r+0.12,h=0.9);
        }
    }
}
module cap_stop_shoulder() {
    // Annular, printable ramp: leaves the cane exits completely open.
    difference() {
        translate([0,0,cap_bottom-2.4]) cylinder(r1=body_r,r2=body_r+2,h=2.4);
        translate([0,0,cap_bottom-2.4-eps]) cylinder(r=body_r-wall,h=2.4+2*eps);
    }
}
module locating_stud() {
    // 圆榫与原螺丝柱共轴，减少零件和独立凸台 | Stud shares the screw-post axis.
    translate([ring_bolt_r,0,body_h-eps]) {
        cylinder(d=locator_d,h=locator_h-locator_chamfer+eps);
        translate([0,0,locator_h-locator_chamfer+eps])
            cylinder(d1=locator_d,d2=locator_d-2*locator_chamfer,h=locator_chamfer);
    }
}
module ring_thread_cutout() {
    // 与 reed-guillotine 相同的 BOSL2 真螺纹孔；顶部导入、底部不穿出。
    // Real BOSL2 M4 x0.7 internal thread, with lead-in and blind bottom.
    translate([ring_bolt_r,0,body_h+locator_h+eps])
        screw_hole("M4",length=ring_thread_depth+eps,thread=true,
            tolerance="8G",bevel1=false,bevel2=true,anchor=TOP,$slop=cfg_m4_thread_slop);
}
module ring_mount() {
    // 单个 D 形轮廓：内端半圆护住螺孔，外侧矩形墙一直连到侧壁。
    // One D-shaped extrusion joins the rounded screw seat to the shell.
    steps=ceil(circle_segments(ring_post_r)/2);
    linear_extrude(height=body_h+top_join) polygon(concat(
        [[ring_wall_end,-ring_post_r],[ring_wall_end,ring_post_r]],
        [for(i=[0:steps]) let(t=90+180*i/steps)
            [ring_bolt_r+ring_post_r*cos(t),ring_post_r*sin(t)]]));
}
module body_core(with_thread=true) {
    difference() {
        union() {
            difference() {
                cylinder(r=body_r,h=body_h+top_join);
                translate([0,0,-eps]) cylinder(r=body_r-wall,h=body_h+top_join+2*eps);
            }
            difference() {
                cylinder(r=body_r,h=3);
                translate([0,0,-eps]) cylinder(r=exit_r,h=3+2*eps);
            }
            support_fins();
            guide_hub();
            radial(offset=180/n) ring_mount();
            if(with_thread) { external_thread(); cap_stop_shoulder(); }
        }
        // 合并后统一裁平顶面，避免多个共面顶面生成接缝退化面。
        // Trim the united rim, fins and posts once, avoiding coplanar seams.
        translate([-2*cap_r,-2*cap_r,body_h]) cube([4*cap_r,4*cap_r,top_join+eps]);
        outer_edge_chamfer(body_r,0);
        radial() { blade_channel(); clamp_cutouts(); }
    }
}
module body(with_thread=true) {
    difference() {
        union() {
            body_core(with_thread);
            radial(offset=180/n) locating_stud();
        }
        radial(offset=180/n) ring_thread_cutout();
    }
}
module lid_fixing_cutout() {
    translate([0,0,-eps]) cylinder(d=ring_hole_d,h=ring_h+2*eps);
    translate([0,0,ring_head_seat]) cylinder(d=ring_counterbore_d,h=ring_counterbore_depth+eps);
    // 下侧榫孔及入口倒角 | Bottom locating socket and its entry chamfer.
    translate([0,0,-eps]) cylinder(d=locator_d+cfg_locator_diameter_clearance,
        h=locator_h+cfg_locator_depth_clearance+eps);
    translate([0,0,-eps]) cylinder(d1=locator_d+cfg_locator_diameter_clearance+0.6,
        d2=locator_d+cfg_locator_diameter_clearance,h=0.3+eps);
}
module locking_ring() {
    difference() {
        cylinder(r=body_r,h=ring_h);
        outer_edge_chamfer(body_r,ring_h,upper=true);
        translate([0,0,-eps]) cylinder(r=guide_r,h=ring_h+2*eps);
        translate([0,0,ring_h-1]) cylinder(r1=guide_r,r2=guide_r+1,h=1+eps);
        radial(offset=180/n) translate([ring_bolt_r,0,0]) lid_fixing_cutout();
    }
}
module cap_world() {
    // World-coordinate thread matches the male helix. Invert for printing.
    difference() {
        translate([0,0,cap_bottom]) cylinder(r=cap_r,h=cap_h);
        outer_edge_chamfer(cap_r,cap_bottom);
        outer_edge_chamfer(cap_r,cap_top,upper=true);
        translate([0,0,cap_bottom-eps]) cylinder(r=body_r+thread_fit,h=cap_ceiling-cap_bottom+eps);
        helix(body_r,thread_depth,cap_bottom-thread_pitch,thread_end+thread_pitch,thread_fit,thread_zfit);
        // Open-end lead-in; the deep thread is above this chamfer.
        translate([0,0,cap_bottom-eps]) cylinder(r1=body_r+thread_depth+thread_fit+0.1,
            r2=body_r+thread_fit,h=1.2+eps);
    }
    translate([0,0,cap_ceiling-1.5]) difference() {
        cylinder(r=(cane_d+1.5)/2+1.2,h=1.5+eps);
        translate([0,0,-eps]) cylinder(r=(cane_d+1.5)/2,h=1.5+3*eps);
    }
}
module palm_cap() { rotate([180,0,0]) translate([0,0,-cap_top]) cap_world(); }
module coupon() {
    for(i=[0:2]) translate([i*19,0,0]) difference() {
        cube([16,W+4,7]);
        translate([8-(T+cfg_blade_slot_clearance+(i-1)*0.06)/2,2,1.2])
            cube([T+cfg_blade_slot_clearance+(i-1)*0.06,W+0.2,6]);
        translate([8-(back_t+cfg_back_slot_clearance+(i-1)*0.06)/2,2+W-back_w,1.2])
            cube([back_t+cfg_back_slot_clearance+(i-1)*0.06,back_w+0.2,6]);
    }
}
module connection_coupon() {
    // 用小试块验证实际 PETG 的榫孔与金属 M4 配合 | Small PETG locator/M4 fit trial.
    translate([-ring_bolt_r,0,14-body_h]) difference() {
        union() {
            translate([ring_bolt_r,0,body_h-14]) cylinder(d=16,h=14);
            locating_stud();
        }
        ring_thread_cutout();
    }
    translate([21,0,0]) difference() {
        cylinder(d=16,h=ring_h); lid_fixing_cutout();
    }
}
module washer(od,id,h=0.5) { difference() { cylinder(d=od,h=h); translate([0,0,-eps]) cylinder(d=id,h=h+2*eps); } }
module socket_screw(d,length,head_d,head_h,allen) {
    cylinder(d=d,h=length);
    translate([0,0,length]) difference() {
        cylinder(d=head_d,h=head_h);
        translate([0,0,head_h/2]) hex(allen,head_h);
    }
}
module clamp_fasteners() {
    // Under-head plane y=-4.5; tip y=+5.5. Local shaft +Z is reversed to +Y.
    translate([clamp_p[0],clamp_L-clamp_span/2-0.5,clamp_p[1]]) rotate([90,0,0]) {
        socket_screw(clamp_d,clamp_L,4.5,2.5,2);
        translate([0,0,clamp_L-0.5]) washer(6,2.7);
    }
    translate([clamp_p[0],clamp_span/2-clamp_nut_h,clamp_p[1]]) rotate([-90,0,0]) difference() {
        hex(clamp_nut_af,clamp_nut_h);
        translate([0,0,-eps]) cylinder(d=clamp_d,h=clamp_nut_h+2*eps);
    }
}
module ring_screw() {
    screw("M4",length=ring_screw_L,head="socket",drive="hex",tolerance="6g",
        anchor="shaft_top",orient=UP);
}
module ring_fasteners(turns=0) {
    radial(offset=180/n) translate([ring_bolt_r,0,body_h+ring_head_seat+ring_screw_pitch*turns])
        rotate([0,0,ring_screw_spin+360*turns]) ring_screw();
}
module assembly(exploded=false) {
    color([0.18,0.35,0.40]) render(convexity=30) body();
    color([0.95,0.60,0.17]) translate([0,0,body_h+(exploded?22:0)]) render(convexity=25) locking_ring();
    if(cfg_show_hardware) {
        radial() translate([0,0,exploded?12:0]) blade_visual();
        color("silver") if(!exploded) { radial() clamp_fasteners(); ring_fasteners(); }
    }
    // Detached cap is open upward to show its female thread. Exploded cap
    // has its normal assembled orientation; neither pose is transparent.
    color([0.26,0.47,0.52]) if(exploded)
        translate([0,0,cap_top+50]) rotate([180,0,0]) render(convexity=30) palm_cap();
    else translate([2*cap_r+10,0,0]) render(convexity=30) palm_cap();
}
module direction_arrow() {
    color([0.88,0.18,0.10]) translate([body_r+9,0,body_h+ring_h+5]) {
        cylinder(r1=0,r2=2.8,h=5); translate([0,0,5]) cylinder(r=1,h=18);
    }
}
module operation() {
    assembly(); direction_arrow();
    color([0.80,0.63,0.28]) translate([0,0,body_h+ring_h+3]) difference() {
        cylinder(d=cane_d,h=45);
        translate([0,0,-eps]) cylinder(d=cane_d*0.65,h=45+2*eps);
    }
}
module split_sector() {
    half=180/n;
    shift=(fin_t/2+0.15)/sin(half);
    translate([shift*cos(half),shift*sin(half),-1]) linear_extrude(height=body_h+2) difference() {
        polygon(concat([[0,0]],[for(t=[0:2:360/n]) [cane_max/2*cos(t),cane_max/2*sin(t)]]));
        circle(r=2.75);
    }
}

module diagnostic() {
    // Thread is outside the blade/cane envelope; omit it from those checks.
    if(cfg_check=="blade_body") intersection() { body(false); radial() blade_metal(); }
    else if(cfg_check=="clamp_blade") intersection() { blade_metal(); clamp_fasteners(); }
    else if(cfg_check=="clamp_body") intersection() { body(false); radial() clamp_fasteners(); }
    else if(cfg_check=="insertion") intersection() {
        body(false); translate([0,0,cfg_insertion]) blade_metal();
    }
    else if(cfg_check=="positive_pin") intersection() {
        translate([sin(a),0,cos(a)]) blade_metal(); clamp_fasteners();
    }
    else if(cfg_check=="cap_fit") intersection() {
        translate([0,0,thread_pitch*cfg_cap_turns]) rotate([0,0,360*cfg_cap_turns]) cap_world();
        // Solid envelope conservatively contains the entire body, blades,
        // clamp fasteners and guide; protruding screw heads remain explicit.
        union() { cylinder(r=body_r,h=body_h+ring_h); external_thread(); cap_stop_shoulder(); ring_fasteners(); }
    }
    else if(cfg_check=="thread_control") intersection() { translate([0,0,thread_pitch/2]) cap_world(); external_thread(); }
    else if(cfg_check=="cap_stop") intersection() { translate([0,0,-0.2]) cap_world(); cap_stop_shoulder(); }
    else if(cfg_check=="split_exit") intersection() { body(false); radial() split_sector(); }
    else if(cfg_check=="body_ring") intersection() { body(false); translate([0,0,body_h]) locking_ring(); }
    else if(cfg_check=="lid_insertion") intersection() {
        body(false); translate([0,0,body_h+cfg_insertion]) locking_ring();
    }
    else if(cfg_check=="locator_control") intersection() {
        body(false); translate([0.5,0,body_h+1]) locking_ring();
    }
    else if(cfg_check=="ring_screw_fit") intersection() { body(false); ring_fasteners(cfg_cap_turns); }
    else if(cfg_check=="ring_screw_lid") intersection() {
        translate([0,0,body_h]) locking_ring(); ring_fasteners();
    }
    else if(cfg_check=="ring_head_stop") intersection() {
        translate([0,0,body_h]) locking_ring(); translate([0,0,-0.2]) ring_fasteners();
    }
    else if(cfg_check=="m4_phase_control") intersection() {
        body(false);
        radial(offset=180/n) translate([ring_bolt_r,0,body_h+ring_head_seat]) rotate([0,0,ring_screw_spin+180]) ring_screw();
    }
    else if(cfg_check=="body_core_mesh") body(false);
    else if(cfg_check=="blade_mesh") blade_metal();
    else if(cfg_check=="thread_mesh") helix(body_r,thread_depth,thread_start,thread_end);
    else if(cfg_check=="clamp_screw_mesh") socket_screw(clamp_d,clamp_L,4.5,2.5,2);
    else if(cfg_check=="ring_screw_mesh") translate([0,0,ring_screw_L]) ring_screw();
    else if(cfg_check=="clamp_nut_mesh") difference() { hex(clamp_nut_af,clamp_nut_h); translate([0,0,-eps]) cylinder(d=clamp_d,h=clamp_nut_h+2*eps); }
    else if(cfg_check=="clamp_washer_mesh") washer(6,2.7);
    else if(cfg_check=="metrics") {
        echo(metrics=[2*(body_r+2),body_h+locator_h,2*cap_r,cap_top,cap_h,a,clamp_p[0],clamp_p[1]]);
        echo(clamp_support=[clamp_inner_r,clamp_span,fin_t,clamp_edge_margin]);
        echo(guide_hub=[hub_r,hub_h,hub_round,edge_inner_z]);
        echo(fin_root=[fin_root_z,fin_root_round,hub_projection]);
        echo(ring_mount=[body_r,ring_bolt_r,ring_wall_end,ring_post_r,body_h]);
        echo(edge_chamfer=[cfg_edge_chamfer,edge_chamfer_max,edge_min_lip,edge_min_wall]); cube(1);
    } else assert(false,"Unknown diagnostic");
}
module validate() {
    assert(cfg_instrument=="oboe" || cfg_instrument=="bassoon","Unknown instrument");
    assert(cane_d>=cane_min && cane_d<=cane_max,"Cane OD outside supported range");
    assert(cfg_edge_chamfer>=0 && cfg_edge_chamfer<=edge_chamfer_max+0.000001,
        str("Outer chamfer exceeds the wall-based limit: ",edge_chamfer_max," mm"));
    assert(ring_bolt_r<ring_wall_end,"Lid mount must extend outwards into the shell");
    assert(ring_bolt_r-ring_post_r>exit_r,"Lid mounting wall intrudes into the cane exit");
    assert(L>=37.5 && L<=40 && W>=18 && W<=20,"Measure actual blade length/width");
    assert(T>=0.20 && T<=0.30 && back_t>=0.4 && back_t<=1.2,"Measure actual blade thickness/back");
    assert(back_w>=4 && back_w<=8 && notch_v+notch_w/2<W-back_w,"Notch overlaps backing; measure it");
    assert(notch_w>=clamp_hole_d+0.1 && notch_d>=clamp_hole_d+0.4,"M2.5 clamp does not fit notch");
    assert(notch_v-notch_w/2>2 && notch_v+notch_w/2<W,"Notch reaches cutting bevel or is outside blade");
    assert(cfg_blade_slot_clearance>=0.08 && cfg_blade_slot_clearance<=0.30,"Invalid face fit");
    assert(cfg_back_slot_clearance>=0.1 && cfg_back_slot_clearance<=0.35,"Invalid back fit");
    assert(thread_fit>=0.15 && thread_fit<=0.5 && thread_zfit>=0.08 && thread_zfit<=0.3,"Invalid thread fit");
    assert(fin_t>back_t+cfg_back_slot_clearance+1.5,"Fin too thin");
    assert(exit_r>cane_max/2+fin_t/(2*sin(180/n)),"Insufficient split exit clearance");
    assert(clamp_inner_r>exit_r,"Clamping web intrudes into cane exit");
    assert(clamp_p[1]+clamp_edge_margin<body_h,"Insufficient material above the clamp hole");
    assert(locator_d>=6.5 && locator_d<=7.5 && locator_h>=2 && locator_h<=3,"Invalid locating stud size");
    assert(cfg_locator_diameter_clearance>=0.15 && cfg_locator_diameter_clearance<=0.6,"Invalid locating socket fit");
    assert(cfg_locator_depth_clearance>=0.15 && cfg_locator_depth_clearance<=0.5,"Invalid locating socket depth fit");
    assert(ring_head_seat-locator_h-cfg_locator_depth_clearance>=1.5,"Insufficient counterbore floor");
    assert(cfg_m4_thread_slop>=0 && cfg_m4_thread_slop<=0.08,"Invalid M4 printing fit");
    assert(ring_screw_L-ring_head_seat+locator_h>=8,"Insufficient M4 engagement");
    assert(ring_thread_depth>ring_screw_L-ring_head_seat+locator_h+1,"M4 screw bottoms out");
    assert(2*cap_r<90,"Envelope outside supported bounds");
    children();
}
validate() {
    if(cfg_check!="") diagnostic();
    else if(cfg_part=="body") render(convexity=30) body();
    else if(cfg_part=="locking_ring") render(convexity=25) locking_ring();
    else if(cfg_part=="palm_cap") render(convexity=30) palm_cap();
    else if(cfg_part=="coupon") render(convexity=20) coupon();
    else if(cfg_part=="connection_coupon") render(convexity=30) connection_coupon();
    else if(cfg_part=="assembly") assembly();
    else if(cfg_part=="exploded") assembly(true);
    else if(cfg_part=="operation") operation();
    else if(cfg_part=="section") intersection() {
        assembly(); translate([-2*cap_r,0,-eps]) cube([5*cap_r,2*cap_r,cap_top+100]);
    } else if(cfg_part=="print_plate") {
        body(); translate([2*cap_r+6,0,0]) locking_ring();
        translate([cap_r+3,2*cap_r+6,0]) palm_cap();
    } else assert(false,"Unknown part");
}
