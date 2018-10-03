import simd

struct Ray {
    var origin: simd_float3
    var direction: simd_float3

    init(origin: simd_float3, direction: simd_float3) {
        self.origin = origin
        self.direction = direction
    }

    func dist(with plane: Plane) -> Float {
        let ndd = dot(plane.normal, direction)
        if ndd.isZero {
            return 0.0
        }

        let ndo = dot(plane.normal, origin)
        return (plane.dist - ndo) / ndd
    }
}
