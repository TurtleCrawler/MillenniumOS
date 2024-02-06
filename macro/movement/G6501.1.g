; G6501.1.g: BOSS - EXECUTE
;
; Probe the outside surface of a boss.
;
; J, K and L indicate the start X, Y and Z
; positions of the probe, which should be an
; approximate center of the boss, below the
; top surface.
; H indicates the approximate boss diameter,
; and is used to calculate a probing radius along
; with T, the clearance distance.
; If W is specified, the WCS origin will be set
; to the center of the boss.


if { exists(param.W) && param.W != null && (param.W < 1 || param.W > #global.mosWorkOffsetCodes) }
    abort { "WCS number (W..) must be between 1 and " ^ #global.mosWorkOffsetCodes ^ "!" }

if { !exists(param.J) || !exists(param.K) || !exists(param.L) }
    abort { "Must provide a start position to probe from using J, K and L parameters!" }

if { !exists(param.H) }
    abort { "Must provide an approximate boss diameter using the H parameter!" }

var probeId = { global.mosFeatureTouchProbe ? global.mosTouchProbeID : null }

var clearance = {(exists(param.T) ? param.T : global.mosProbeClearance)}
var overtravel = {(exists(param.O) ? param.O : global.mosProbeOvertravel)}

; Switch to probe tool if necessary
var needsProbeTool = { global.mosProbeToolID != state.currentTool }
if { var.needsProbeTool }
    T T{global.mosProbeToolID}

; We add the clearance distance to the boss
; radius to ensure we move clear of the boss
; before dropping to probe height.
var cR = { (param.H / 2) + var.clearance }

; J = start position X
; K = start position Y
; L = start position Z - our probe height

; Start position is operator chosen center of the boss
var sX   = { param.J }
var sY   = { param.K }
var sZ   = { param.L }

; Calculate probing directions using approximate boss radius
; Angle is in degrees
var angle = 120

; For each probe point: start x, start y, target x, target y
var dirXY = vector(3, {null, null, null, null })

; The start position is the approximate radius of the boss plus
; the clearance at 3 points around the center of the boss, at
; 120 degree intervals.
; The target position is the approximate radius of the boss minus
; the overtravel distance, at the same 3 points around the center
; of the boss, at 120 degree intervals.
set var.dirXY[0] = { var.sX + var.cR, var.sY, var.sX + (var.cR - var.overtravel) * cos(radians(var.angle)), var.sY + (var.cR - var.overtravel) * sin(radians(var.angle)) }
set var.dirXY[1] = { var.sX + var.cR * cos(radians(var.angle)), var.sY + var.cR * sin(radians(var.angle)), var.sX + (var.cR - var.overtravel) * cos(radians(var.angle)), var.sY + (var.cR - var.overtravel) * sin(radians(var.angle))}
set var.dirXY[2] = { var.sX + var.cR * cos(radians(2 * var.angle)), var.sY + var.cR * sin(radians(2 * var.angle)), var.sX + (var.cR - var.overtravel) * cos(radians(2 * var.angle)), var.sY + (var.cR - var.overtravel) * sin(radians(2 * var.angle))}

; Boss edge co-ordinates for 3 probed points
var pXY  = { null, null, null }

var safeZ = { move.axes[2].machinePosition }

; Probe each of the 3 points
while { iterations < #var.dirXY }
    ; Perform a probe operation towards the center of the boss
    G6512 I{var.probeId} J{var.dirXY[iterations][0]} K{var.dirXY[iterations][1]} L{var.sZ} X{var.dirXY[iterations][2]} Y{var.dirXY[iterations][3]}

    ; Save the probed co-ordinates
    set var.pXY[iterations] = { global.mosProbeCoordinate[0], global.mosProbeCoordinate[1] }

; Calculate the slopes, midpoints, and perpendicular bisectors
var sM1 = { (var.pXY[1][1] - var.pXY[0][1]) / (var.pXY[1][0] - var.pXY[0][0]) }
var sM2 = { (var.pXY[2][1] - var.pXY[1][1]) / (var.pXY[2][0] - var.pXY[1][0]) }

var m1X = { (var.pXY[1][0] + var.pXY[0][0]) / 2 }
var m1Y = { (var.pXY[1][1] + var.pXY[0][1]) / 2 }
var m2X = { (var.pXY[2][0] + var.pXY[1][0]) / 2 }
var m2Y = { (var.pXY[2][1] + var.pXY[1][1]) / 2 }

var pM1 = { -1 / var.sM1 }
var pM2 = { -1 / var.sM2 }

; Solve the equations of the lines formed by the perpendicular bisectors to find the circumcenter X,Y
var cX = { (var.pM2 * var.m2X - var.pM1 * var.m1X + var.m1Y - var.m2Y) / (var.pM2 - var.pM1) }
var cY = { var.pM1 * (var.cX - var.m1X) + var.m1Y }

; Calculate the radii from the circumcenter to each of the probed points
var r1 = { sqrt(pow((var.pXY[0][0] - var.cX), 2) + pow((var.pXY[0][1] - var.cY), 2)) }
var r2 = { sqrt(pow((var.pXY[1][0] - var.cX), 2) + pow((var.pXY[1][1] - var.cY), 2)) }
var r3 = { sqrt(pow((var.pXY[2][0] - var.cX), 2) + pow((var.pXY[2][1] - var.cY), 2)) }

; Calculate the average radius
var avgR = { (var.r1 + var.r2 + var.r3) / 3 }

; Update global vars
set global.mosWorkPieceCenterPos = { var.cX, var.cY }
set global.mosWorkPieceRadius = { var.avgR }
set global.mosWorkPieceBoundingBox = { var.cX - var.avgR, var.cY - var.avgR, var.cX + var.avgR, var.cY + var.avgR }

; Confirm we are at the safe Z height
G6550 I{var.probeId} Z{var.safeZ}

; Move to the calculated center of the boss
G6550 I{var.probeId} X{var.cX} Y{var.cY}

if { !global.mosExpertMode }
    echo { "Boss - Center X=" ^ global.mosWorkPieceCenterPos[0] ^ " Y=" ^ global.mosWorkPieceCenterPos[1] ^ " R=" ^ global.mosWorkPieceRadius }
else
    echo { "global.mosWorkPieceCenterPos=" ^ global.mosWorkPieceCenterPos }
    echo { "global.mosWorkPieceRadius=" ^ global.mosWorkPieceRadius }
    echo { "global.mosWorkPieceBoundingBox=" ^ global.mosWorkPieceBoundingBox }

; Set WCS origin to the probed boss center, if requested
if { exists(param.W) && param.W != null }
    echo { "Setting WCS " ^ param.W ^ " X,Y origin to center of boss" }
    G10 L2 P{param.W} X{var.cX} Y{var.cY}

; Save code of last probe cycle
set global.mosLastProbeCycle = "G6501"