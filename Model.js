.pragma library

function parseCpuUsage(raw) {
    var lines = raw.trim().split('\n')
    var cpuLine = lines.find(function(l) { return l.startsWith('cpu ') })
    if (!cpuLine) return { user: 0, nice: 0, system: 0, idle: 0, total: 0 }
    var parts = cpuLine.trim().split(/\s+/).slice(1).map(Number)
    var user = parts[0] || 0
    var nice = parts[1] || 0
    var system = parts[2] || 0
    var idle = parts[3] || 0
    var iowait = parts[4] || 0
    var irq = parts[5] || 0
    var softirq = parts[6] || 0
    var steal = parts[7] || 0
    var guest = parts[8] || 0
    var guest_nice = parts[9] || 0
    var total = user + nice + system + idle + iowait + irq + softirq + steal
    var busy = total - idle - iowait
    return {
        user: user,
        nice: nice,
        system: system,
        idle: idle,
        iowait: iowait,
        total: total,
        busy: busy,
        usagePercent: total > 0 ? Math.round((busy / total) * 100) : 0
    }
}

function parseGpuUsage(raw) {
    try {
        var lines = raw.trim().split('\n')
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            // Skip header row
            if (line.includes('utilization') && line.includes('%')) continue
            var parts = line.split(',').map(function(p) { return p.trim() }).filter(function(p) { return p !== '' })
            if (parts.length >= 6) {
                var temp = parseInt(parts[1]) || 0
                var gpuUtil = parseInt(parts[2]) || 0
                var power = parseInt(parts[3]) || 0
                var memUsed = parseInt(parts[4]) || 0
                var memTotal = parseInt(parts[5]) || 0
                return {
                    gpuUtil: gpuUtil,
                    memUsed: memUsed,
                    memTotal: memTotal,
                    memPercent: memTotal > 0 ? Math.round((memUsed / memTotal) * 100) : 0,
                    temp: temp,
                    power: power
                }
            }
        }
    } catch (e) {
        console.log("GPU parse error:", e)
    }
    return { gpuUtil: 0, memUsed: 0, memTotal: 0, memPercent: 0, temp: 0, power: 0 }
}

function parsePowerProfiles(raw) {
    var lines = raw.trim().split('\n')
    var profiles = []
    var activeProfile = ""
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line === '') continue
        var parts = line.split('\t')
        var name = parts[0]
        var active = parts.length > 1 && parts[1] === "1"
        profiles.push(name)
        if (active) activeProfile = name
    }
    return { profiles: profiles, activeProfile: activeProfile }
}

function profileIcon(profile) {
    switch (profile) {
        case "power-saver": return "󰾆"
        case "balanced": return "󰾅"
        case "performance": return "󰓅"
        default: return "󰚥"
    }
}

function formatTemp(c) {
    return c > 0 ? c + "°C" : "—"
}

function formatPower(w) {
    return w > 0 ? w + "W" : "—"
}