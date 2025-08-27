#!/usr/bin/env python3
"""
Simplified Kick-up Counter Demo
A minimal implementation showing the core algorithm used in both Python and iOS versions.
"""

import cv2
import numpy as np
from cvzone.PoseModule import PoseDetector

# Simple configuration
CONTACT_THRESHOLD = 70  # Distance threshold for kick detection
COOLDOWN_FRAMES = 13    # Frames to wait between detections
CONTACT_LANDMARKS = [31, 32]  # Foot landmarks (left, right)

def detect_ball_simple(img):
    """
    Simplified ball detection using color and shape heuristics.
    In production, this would be replaced with YOLO or Core ML.
    """
    # Convert to HSV for better color detection
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    
    # Define range for ball colors (adjust for your ball)
    # This example looks for white/light colored balls
    lower = np.array([0, 0, 200])
    upper = np.array([180, 30, 255])
    
    # Create mask and find contours
    mask = cv2.inRange(hsv, lower, upper)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Find the largest circular contour
    for contour in contours:
        area = cv2.contourArea(contour)
        if area > 500:  # Minimum area threshold
            # Check if contour is roughly circular
            perimeter = cv2.arcLength(contour, True)
            if perimeter > 0:
                circularity = 4 * np.pi * area / (perimeter * perimeter)
                if 0.7 < circularity < 1.3:  # Roughly circular
                    M = cv2.moments(contour)
                    if M["m00"] != 0:
                        cx = int(M["m10"] / M["m00"])
                        cy = int(M["m01"] / M["m00"])
                        return (cx, cy)
    
    return None

def main():
    """
    Main demo function showing the core kick detection algorithm
    """
    print("🏈 Kick-up Counter Demo")
    print("👋 This demonstrates the core algorithm used in both Python and iOS versions")
    print("📱 Press 'q' to quit, 'r' to reset counter")
    
    # Initialize camera (use 0 for webcam, or path to video file)
    cap = cv2.VideoCapture(0)  # Change to video path if needed
    
    if not cap.isOpened():
        print("❌ Could not open camera/video")
        return
    
    # Initialize pose detector
    detector = PoseDetector()
    
    # Counter variables
    kickup_count = 0
    cooldown_counter = 0
    distance_history = []
    
    print("✅ Starting detection... Point camera at kick-up activity")
    
    while True:
        success, img = cap.read()
        if not success:
            break
        
        # Flip image for webcam (more intuitive)
        if cap.get(cv2.CAP_PROP_FRAME_WIDTH) > 0:
            img = cv2.flip(img, 1)
        
        # Detect pose
        img = detector.findPose(img, draw=True)
        lmList, _ = detector.findPosition(img, draw=False)
        
        # Detect ball (simplified)
        ball_pos = detect_ball_simple(img)
        
        # Update cooldown
        if cooldown_counter > 0:
            cooldown_counter -= 1
        
        min_distance = float('inf')
        
        # Process detections
        if ball_pos and lmList:
            # Draw ball detection
            cv2.circle(img, ball_pos, 15, (0, 255, 0), cv2.FILLED)
            cv2.putText(img, "BALL", (ball_pos[0]-20, ball_pos[1]-20), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            
            # Check distances to contact points
            for lm_index in CONTACT_LANDMARKS:
                if lm_index < len(lmList):
                    lm_pos = lmList[lm_index][:2]  # Get x, y coordinates
                    
                    # Calculate distance
                    distance = np.sqrt((ball_pos[0] - lm_pos[0])**2 + 
                                     (ball_pos[1] - lm_pos[1])**2)
                    min_distance = min(min_distance, distance)
                    
                    # Draw distance line
                    color = (0, 255, 255)  # Yellow
                    if distance < CONTACT_THRESHOLD:
                        color = (0, 0, 255)  # Red for contact
                    
                    cv2.line(img, ball_pos, tuple(lm_pos), color, 2)
                    
                    # Check for kick detection
                    if distance < CONTACT_THRESHOLD and cooldown_counter == 0:
                        kickup_count += 1
                        cooldown_counter = COOLDOWN_FRAMES
                        print(f"🎯 KICK #{kickup_count} detected! Distance: {distance:.1f}px")
        
        # Store distance for visualization
        distance_history.append(min_distance if min_distance != float('inf') else 200)
        if len(distance_history) > 100:
            distance_history.pop(0)
        
        # Draw UI elements
        # Kick counter
        counter_color = (0, 255, 0) if cooldown_counter == 0 else (0, 165, 255)
        cv2.rectangle(img, (10, 10), (300, 100), (0, 0, 0), -1)
        cv2.rectangle(img, (10, 10), (300, 100), counter_color, 3)
        cv2.putText(img, f"Kicks: {kickup_count}", (20, 60), 
                   cv2.FONT_HERSHEY_SIMPLEX, 1.8, counter_color, 3)
        
        # Status indicator
        status = "COOLDOWN" if cooldown_counter > 0 else "READY"
        status_color = (0, 165, 255) if cooldown_counter > 0 else (0, 255, 0)
        cv2.putText(img, status, (20, 130), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, status_color, 2)
        
        # Distance indicator
        if min_distance != float('inf'):
            cv2.putText(img, f"Distance: {min_distance:.1f}px", (20, 160),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        # Threshold line (visual reference)
        cv2.putText(img, f"Threshold: {CONTACT_THRESHOLD}px", (20, 190),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (128, 128, 128), 2)
        
        # Simple distance plot at bottom
        plot_height = 50
        plot_y = img.shape[0] - plot_height - 10
        cv2.rectangle(img, (10, plot_y), (400, img.shape[0] - 10), (0, 0, 0), -1)
        
        if len(distance_history) > 1:
            points = []
            for i, dist in enumerate(distance_history[-50:]):  # Last 50 points
                x = 10 + int(i * 380 / 50)
                y = plot_y + plot_height - int((min(dist, 200) / 200) * plot_height)
                points.append((x, y))
            
            # Draw distance line
            for i in range(len(points) - 1):
                color = (0, 255, 0) if cooldown_counter > 0 else (0, 0, 255)
                cv2.line(img, points[i], points[i + 1], color, 2)
        
        # Instructions
        cv2.putText(img, "Press 'q' to quit, 'r' to reset", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        
        # Display result
        cv2.imshow("Kick-up Counter Demo", img)
        
        # Handle keyboard input
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('r'):
            kickup_count = 0
            cooldown_counter = 0
            distance_history.clear()
            print("🔄 Counter reset!")
    
    # Cleanup
    cap.release()
    cv2.destroyAllWindows()
    print(f"🏁 Final count: {kickup_count} kick-ups")

if __name__ == "__main__":
    main()