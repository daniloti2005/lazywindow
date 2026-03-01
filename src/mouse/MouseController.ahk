#Requires AutoHotkey v2.0

class MouseController {
    static MoveTo(x, y) {
        MouseMove(x, y)
    }
    
    static MoveToCenter(bounds) {
        centerX := bounds.x + (bounds.width // 2)
        centerY := bounds.y + (bounds.height // 2)
        this.MoveTo(centerX, centerY)
        return {x: centerX, y: centerY}
    }
    
    static LeftClick() {
        Click("Left")
    }
    
    static RightClick() {
        Click("Right")
    }
    
    static ClickAt(x, y, button := "Left") {
        this.MoveTo(x, y)
        Sleep(50)
        Click(button)
    }
    
    static GetPosition() {
        MouseGetPos(&x, &y)
        return {x: x, y: y}
    }
    
    static ScrollLeft(clicks := 3) {
        Loop clicks {
            Click("WheelLeft")
        }
    }
    
    static ScrollRight(clicks := 3) {
        Loop clicks {
            Click("WheelRight")
        }
    }
    
    static SmoothMove(targetX, targetY, duration := 200) {
        ; Get current position
        MouseGetPos(&startX, &startY)
        
        ; Calculate steps based on duration (50 steps for 200ms)
        steps := Max(20, duration // 4)
        sleepTime := duration // steps
        
        Loop steps {
            ; Calculate progress (0 to 1)
            t := A_Index / steps
            
            ; Ease-in-out function: slow start, fast middle, slow end
            if (t < 0.5) {
                progress := 2 * t * t
            } else {
                progress := 1 - ((-2 * t + 2) ** 2) / 2
            }
            
            ; Calculate current position
            currentX := startX + (targetX - startX) * progress
            currentY := startY + (targetY - startY) * progress
            
            MouseMove(currentX, currentY)
            Sleep(sleepTime)
        }
        
        ; Ensure final position is exact
        MouseMove(targetX, targetY)
    }
}
