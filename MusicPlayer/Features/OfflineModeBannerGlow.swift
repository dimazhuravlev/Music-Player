import SwiftUI

/// Баннер Offline Mode: два размытых эллипса с разными траекториями; волна в бордере.
struct OfflineModeBannerGlow: ViewModifier {
    var cornerRadius: CGFloat = 22
    
    /// Период оборота «волны» по бордеру (секунды); меньше — движение заметнее.
    private var borderSweepPeriod: Double { 3.75 }
    /// Период орбиты/вращения первого эллипса (секунды).
    private var ellipseMotionPeriod: Double { 4.95 }
    /// Период орбиты/вращения второго эллипса — другой темп + фаза π в коде (противофаза).
    private var ellipse2MotionPeriod: Double { 7.4 }
    /// Общий период пульсации opacity; большой эллипс 5–25%, малый 5–15%, противофаза (сдвиг π).
    private var ellipseOpacityPulsePeriod: Double { 3.75 }
    
    private var borderStrokeColor: Color {
        Color(red: 0.6, green: 0.12, blue: 1)
    }
    
    private var ellipseGradient: LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.4, green: 0.08, blue: 1), location: 0),
                Gradient.Stop(color: Color(red: 0.91, green: 0, blue: 0.99), location: 1)
            ],
            startPoint: UnitPoint(x: 0, y: 0),
            endPoint: UnitPoint(x: 1, y: 1)
        )
    }
    
    private var secondEllipseGradient: LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 1, green: 0.08, blue: 0.86), location: 0),
                Gradient.Stop(color: Color(red: 0.88, green: 0, blue: 0.37), location: 1)
            ],
            startPoint: UnitPoint(x: 0, y: 0),
            endPoint: UnitPoint(x: 1, y: 1)
        )
    }
    
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phaseDegrees = (t.truncatingRemainder(dividingBy: borderSweepPeriod) / borderSweepPeriod) * 360
            let ellipsePhaseDegrees = (t.truncatingRemainder(dividingBy: ellipseMotionPeriod) / ellipseMotionPeriod) * 360
            let ellipseRadians = ellipsePhaseDegrees * Double.pi / 180
            
            let pulseT = t.truncatingRemainder(dividingBy: ellipseOpacityPulsePeriod) / ellipseOpacityPulsePeriod
            let pulseAngle = pulseT * 2 * Double.pi
            let ellipseOpacity = 0.05 + ((sin(pulseAngle) + 1) / 2) * 0.2
            let ellipse2Opacity = 0.05 + ((sin(pulseAngle + Double.pi) + 1) / 2) * 0.1
            
            let ellipse2PhaseDegrees = (t.truncatingRemainder(dividingBy: ellipse2MotionPeriod) / ellipse2MotionPeriod) * 360
            let ellipse2Radians = ellipse2PhaseDegrees * Double.pi / 180
            let ellipse2RadiansShifted = ellipse2Radians + Double.pi
            
            content
                .background {
                    GeometryReader { geo in
                        let w = max(geo.size.width, 1)
                        let h = max(geo.size.height, 1)
                        let ellW: CGFloat = 400
                        let ellH: CGFloat = 220
                        let orbitX = w * 0.16
                        let orbitY = h * 0.11
                        
                        let ell2W: CGFloat = 215.81543
                        let ell2H: CGFloat = 112.22804
                        let orbit2X = w * 0.22
                        let orbit2Y = h * 0.16
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                            
                            Ellipse()
                                .fill(ellipseGradient)
                                .frame(width: ellW, height: ellH)
                                .blur(radius: 40)
                                .opacity(ellipseOpacity)
                                .rotationEffect(.degrees(12.15 + ellipsePhaseDegrees))
                                .position(
                                    x: w * 0.5 + CGFloat(cos(ellipseRadians)) * orbitX,
                                    y: h * 0.42 + CGFloat(sin(ellipseRadians)) * orbitY
                                )
                            
                            Ellipse()
                                .fill(secondEllipseGradient)
                                .frame(width: ell2W, height: ell2H)
                                .blur(radius: 48)
                                .opacity(ellipse2Opacity)
                                .rotationEffect(.degrees(-22 + (ellipse2PhaseDegrees + 180) * -1.15))
                                .position(
                                    x: w * 0.52 + CGFloat(sin(ellipse2RadiansShifted * 1.05 + 0.9)) * orbit2X,
                                    y: h * 0.52 + CGFloat(cos(ellipse2RadiansShifted * 0.78 + 1.4)) * orbit2Y
                                )
                        }
                        .frame(width: w, height: h)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }
                }
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .inset(by: 0.5)
                            .stroke(borderStrokeColor, lineWidth: 1)
                        
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.clear, location: 0),
                                        .init(color: Color.clear, location: 0.04),
                                        .init(color: borderStrokeColor.opacity(0.45), location: 0.16),
                                        .init(color: borderStrokeColor.opacity(0.55), location: 0.24),
                                        .init(color: Color.white.opacity(0.55), location: 0.32),
                                        .init(color: Color.white.opacity(0.75), location: 0.38),
                                        .init(color: Color(red: 0.93, green: 0.55, blue: 1), location: 0.40),
                                        .init(color: Color.white.opacity(0.95), location: 0.44),
                                        .init(color: Color.white.opacity(0.95), location: 0.56),
                                        .init(color: Color(red: 0.93, green: 0.55, blue: 1), location: 0.60),
                                        .init(color: Color.white.opacity(0.75), location: 0.66),
                                        .init(color: Color.white.opacity(0.55), location: 0.72),
                                        .init(color: borderStrokeColor.opacity(0.55), location: 0.78),
                                        .init(color: borderStrokeColor.opacity(0.45), location: 0.86),
                                        .init(color: Color.clear, location: 0.94),
                                        .init(color: Color.clear, location: 1)
                                    ]),
                                    center: .center,
                                    angle: .degrees(phaseDegrees)
                                ),
                                lineWidth: 1
                            )
                            .blendMode(.plusLighter)
                    }
                    .opacity(0.1)
                    .allowsHitTesting(false)
                }
        }
    }
}

extension View {
    func offlineModeBannerGlow(cornerRadius: CGFloat = 22) -> some View {
        modifier(OfflineModeBannerGlow(cornerRadius: cornerRadius))
    }
}
