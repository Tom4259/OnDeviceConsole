//
//  OnDeviceConsole.swift
//  OnDeviceConsole
//
//  Created by Tom Redway on 19/11/2025.
//

import SwiftUI

struct ConsoleOverlayView: View {
    
    @State private var consoleManager = ConsoleManager.shared
    @State private var isSheetPresented = false
    @State private var showHint = false
    @State private var hintTimer: Timer?
    @State private var position: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    enum Edge {
        
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    @State private var currentEdge: Edge = .bottomRight
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ZStack(alignment: .topLeading) {
                
                Color.clear
                
                HStack(spacing: 12) {
                    
                    if showHint && currentEdge == .topRight || currentEdge == .bottomRight,
                       let latestLog = consoleManager.logs.last {
                        
                        hintView(log: latestLog)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    floatingButton
                    
                    if showHint && currentEdge == .topLeft || currentEdge == .bottomLeft,
                       let latestLog = consoleManager.logs.last {
                        
                        hintView(log: latestLog)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .offset(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
                
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: position)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEdge)
                
                .onChange(of: consoleManager.logs.count) { _ in
                    showHintTemporarily()
                }
            }
            .onAppear {
                position = calculatePosition(for: currentEdge, in: geometry.size)
            }
            
            .onChange(of: geometry.size) { newSize in
                position = calculatePosition(for: currentEdge, in: newSize)
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            
            consoleSheet
        }
    }
    
    private var floatingButton: some View {
        
        Button(action: {
            if !isDragging {
                isSheetPresented = true
                showHint = false
                hintTimer?.invalidate()
            }
        }) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .gesture(
            
            DragGesture()
                .onChanged { value in
                    
                    isDragging = true
                    dragOffset = value.translation
                    showHint = false
                    hintTimer?.invalidate()
                }
            
                .onEnded { value in
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        
                        snapToNearestEdge(translation: value.translation, velocity: value.velocity)
                        dragOffset = .zero
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isDragging = false
                    }
                }
        )
    }
    
    // Replace the calculatePosition function:

    private func calculatePosition(for edge: Edge, in size: CGSize) -> CGPoint {
        let padding: CGFloat = 16
        let buttonSize: CGFloat = 56
        let topSafeArea: CGFloat = 60 // Safe area for notch/status bar
        let bottomSafeArea: CGFloat = 80 // Safe area for home indicator
        
        switch edge {
        case .topLeft:
            return CGPoint(x: padding, y: padding + topSafeArea)
        case .topRight:
            return CGPoint(x: size.width - buttonSize - padding, y: padding + topSafeArea)
        case .bottomLeft:
            return CGPoint(x: padding, y: size.height - buttonSize - padding - bottomSafeArea)
        case .bottomRight:
            return CGPoint(x: size.width - buttonSize - padding, y: size.height - buttonSize - padding - bottomSafeArea)
        }
    }


    private func snapToNearestEdge(translation: CGSize, velocity: CGSize) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let screenSize = window.bounds.size
        let buttonSize: CGFloat = 56
        
        // Calculate the final position of the button center
        let finalX = position.x + translation.width + (buttonSize / 2)
        let finalY = position.y + translation.height + (buttonSize / 2)
        
        // Determine which edge is closest based on screen center
        let isRight = finalX > screenSize.width / 2
        let isBottom = finalY > screenSize.height / 2
        
        // Account for velocity to make snapping feel more natural
        let velocityThreshold: CGFloat = 500
        let horizontalBias = abs(velocity.width) > velocityThreshold ? (velocity.width > 0) : isRight
        let verticalBias = abs(velocity.height) > velocityThreshold ? (velocity.height > 0) : isBottom
        
        switch (horizontalBias, verticalBias) {
        case (false, false):
            currentEdge = .topLeft
        case (true, false):
            currentEdge = .topRight
        case (false, true):
            currentEdge = .bottomLeft
        case (true, true):
            currentEdge = .bottomRight
        }
        
        position = calculatePosition(for: currentEdge, in: screenSize)
    }
    
    private func hintView(log: ConsoleLog) -> some View {
        
        HStack(spacing: 8) {
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(log.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(log.message)
                    .font(.caption)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: 250)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
    }
    
    private var consoleSheet: some View {
        
        NavigationView {
            
            ScrollViewReader { proxy in
                
                ScrollView {
                    
                    LazyVStack(alignment: .leading, spacing: 12) {
                        
                        ForEach(consoleManager.logs) { log in
                            
                            logRow(log: log)
                                .id(log.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    
                    if let lastLog = consoleManager.logs.last {
                        
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
            .navigationTitle("Console Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    Button("Clear") { consoleManager.clearLogs() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    Button("Done") { isSheetPresented = false }
                }
            }
        }
    }
    
    private func logRow(log: ConsoleLog) -> some View {
        
        VStack(alignment: .leading, spacing: 4) {
            
            Text(log.formattedTime)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(log.message)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func showHintTemporarily() {
        
        hintTimer?.invalidate()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            
            showHint = true
        }
        
        hintTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            
            Task { @MainActor in
            
                withAnimation(.easeInOut(duration: 0.3)) {
                    
                    showHint = false
                }
            }
        }
    }
}

extension View {
    
    public func consoleOverlay() -> some View {
        
        ZStack {
            
            self
            
            ConsoleOverlayView()
        }
    }
}
