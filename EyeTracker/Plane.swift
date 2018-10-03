import simd

struct Plane {
    var normal: simd_float3
    var dist: Float

    init(p1: simd_float3, p2: simd_float3, p3: simd_float3) {
        let p21 = p2 - p1
        let p32 = p3 - p2

        normal = cross(p21, p32)
        normal = normalize(normal)
        dist = dot(normal, p1)
    }
}
