; G6503.g: PROBE WORK PIECE - RECTANGLE BLOCK
;
; Meta macro to gather operator input before executing a
; rectangular block probe cycle (G6503.1).
; The macro will explain to the operator what is about to
; happen and ask for an approximate length and width of
; the block. The macro will then ask the operator to jog
; the probe to the approximate center of the block, and
; enter a probe depth. These values will then be passed
; to the underlying G6503.1 macro to execute the probe cycle.


; Display description of rectangle block probe if not already displayed this session
if { !global.mosExpertMode && !global.mosDescDisplayed[5] }
    M291 P"This probe cycle finds the X and Y co-ordinates of the center of a rectangular block (protruding feature) on a workpiece by probing towards the approximate center of the block from all 4 directions." R"MillenniumOS: Probe Rect. Block " T0 S2
    M291 P"You will be asked to enter an approximate <b>width</b> and <b>height</b> of the block, and a <b>clearance distance</b>." R"MillenniumOS: Probe Rect. Block" T0 S2
    M291 P"These define how far the probe will move away from the center point before moving downwards and probing back towards the edge." R"MillenniumOS: Probe Rect. Block" T0 S2
    M291 P"You will then jog the tool over the approximate center of the block.<br/><b>CAUTION</b>: Jogging in RRF does not watch the probe status, so you could cause damage if moving in the wrong direction!" R"MillenniumOS: Probe Rect. Block" T0 S2
    M291 P"You will then be asked for a <b>probe depth</b>. This is how far the probe will move downwards before probing towards the centerpoint. Press ""OK"" to continue." R"MillenniumOS: Probe Rect. Block" T0 S3
    if { result != 0 }
        abort { "Rectangle block probe aborted!" }
    set global.mosDescDisplayed[5] = true

var needsProbeTool = { global.mosProbeToolID != state.currentTool }
if { var.needsProbeTool }
    T T{global.mosProbeToolID}

M291 P{"Please enter approximate <b>block width</b> in mm.<br/><b>NOTE</b>: <b>Width</b> is measured along the <b>X</b> axis."} R"MillenniumOS: Probe Rect. Block" J1 T0 S6 F100.0
if { result != 0 }
    abort { "Rectangle block probe aborted!" }
else
    var blockWidth = { input }

    M291 P{"Please enter approximate <b>block length</b> in mm.<br/><b>NOTE</b>: <b>Length</b> is measured along the <b>Y</b> axis."} R"MillenniumOS: Probe Rect. Block" J1 T0 S6 F100.0
    if { result != 0 }
        abort { "Rectangle block probe aborted!" }
    else
        var blockLength = { input }

        ; Prompt for clearance distance
        M291 P"Please enter <b>clearance</b> distance in mm.<br/>This is how far far out we move from the expected surface to account for any innaccuracy in the center location." R"MillenniumOS: Probe Rect. Block" J1 T0 S6 F{global.mosProbeClearance}
        if { result != 0 }
            abort { "Rectangle block probe aborted!" }
        else
            var clearance = { input }

            ; Prompt for overtravel distance
            M291 P"Please enter <b>overtravel</b> distance in mm.<br/>This is how far far in we move from the expected surface to account for any innaccuracy in the dimensions." R"MillenniumOS: Probe Rect. Block" J1 T0 S6 F{global.mosProbeOvertravel}
            if { result != 0 }
                abort { "Rectangle block probe aborted!" }
            else
                var overtravel = { input }

                M291 P"Please jog the probe OVER the approximate center of the boss and press OK." R"MillenniumOS: Probe Rect. Block" X1 Y1 Z1 J1 T0 S3
                if { result != 0 }
                    abort { "Rectangle block probe aborted!" }
                else
                    M291 P"Please enter the depth to probe at in mm, relative to the current location. A value of 10 will move the probe downwards 10mm before probing inwards." R"MillenniumOS: Probe Rect. Block" J1 T0 S6 F{global.mosProbeOvertravel}
                    if { result != 0 }
                        abort { "Rectangle block probe aborted!" }
                    else
                        var probingDepth = { input }

                        if { var.probingDepth < 0 }
                            abort { "Probing depth was negative!" }

                        ; Run the block probe cycle
                        if { !global.mosExpertMode }
                            M291 P{"Probe will now move outside each surface and down by " ^ var.probingDepth ^ "mm, before probing towards the center."} R"MillenniumOS: Probe Rect. Block" T0 S3
                            if { result != 0 }
                                abort { "Rectangle block probe aborted!" }

                        G6503.1 W{param.W} H{var.blockWidth} I{var.blockLength} T{var.clearance} O{var.overtravel} J{move.axes[0].machinePosition} K{move.axes[1].machinePosition} L{move.axes[2].machinePosition - var.probingDepth}

                        ;G6503.1 W4 H51 I77 T10 O2 J{move.axes[0].machinePosition} K{move.axes[1].machinePosition} L{move.axes[2].machinePosition - 10}