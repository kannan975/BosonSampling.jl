### full threshold distribution ###

function check_full_threshold_distribution(ev::Event)

    i = ev.input_state
    interf = ev.interferometer

    o = BosonSamplingThresholdDistribution()
    ev_full_distribution_threshold = Event(i, o, interf)

    compute_probability!(ev_full_distribution_threshold)

    o = BosonSamplingDistribution()
    ev_full_distribution = Event(i, o, interf)

    compute_probability!(ev_full_distribution)

    mc = ev_full_distribution.proba_params.probability
    mc_thresholdised = to_threshold(mc)

    mc_threshold = ev_full_distribution_threshold.proba_params.probability

    sort!(mc_thresholdised) 
    sort!(mc_threshold)

    mc_thresholdised.proba ≈ mc_threshold.proba

end


@testset "HOM with ThresholdDetection" begin

    n = 2
    m = 2

    i = Input{Bosonic}(first_modes(n,m))
    interf = Fourier(m)

    detections_hom = all_threshold_detections(n,m, only_photon_number_conserving = !is_lossy(interf))

    probas = [0.5, 0., 0.5]

    for (o, proba) in zip(detections_hom, probas)

        ev = Event(i, o, interf)
        compute_probability!(ev)
        ev.proba_params.probability
        @test ev.proba_params.probability ≈ proba atol = ATOL

    end

    ev = Event(i, detections_hom[1], interf)

    @test check_full_threshold_distribution(ev)


end

@testset "RandHaar with ThresholdDetection and partial distinguishability" begin

    n = 4
    m = 2n
    x = 0.9

    i = Input{OneParameterInterpolation}(first_modes(n,m),x)
    interf = RandHaar(m)

    detections= all_threshold_detections(n,m, only_photon_number_conserving = !is_lossy(interf))

    ev = Event(i, detections[1], interf)

    @test check_full_threshold_distribution(ev)

end

@testset "OneLoopSampler with ThresholdDetection" begin
    

end


n = 3
sparsity = 2
m = sparsity * n

# x = 0.9
# T = OneParameterInterpolation
T = Bosonic
mode_occ = equilibrated_input(sparsity, m)

d = Uniform(0,2pi)
ϕ = nothing # rand(d,m)
η_loss_lines = nothing # 0.86 * ones(m)
η_loss_bs = nothing #0.93 * ones(m-1)
η_loss_source = nothing # get_η_loss_source(m, QuantumDot(13.5/80))

η = rand(m-1)

params = LoopSamplingParameters(n=n, m=m, η = η, η_loss_bs = η_loss_bs, η_loss_lines = η_loss_lines, η_loss_source = η_loss_source, ϕ = ϕ,T=T, mode_occ = mode_occ)

interf = build_loop!(params)

i = Input{T}(mode_occ)
ev = Event(i, BosonSamplingThresholdDistribution(), interf)

@test check_full_threshold_distribution(ev)


n = 2
sparsity = 2
m = sparsity * n

# x = 0.9
# T = OneParameterInterpolation
T = Bosonic
mode_occ = equilibrated_input(sparsity, m)

d = Uniform(0,2pi)
ϕ = nothing # rand(d,m)
η_loss_lines =  0.86 * ones(m)
η_loss_bs = 0.93 * ones(m-1)
η_loss_source = get_η_loss_source(m, QuantumDot(13.5/80))

η = rand(m-1)

params = LoopSamplingParameters(n=n, m=m, η = η, η_loss_bs = η_loss_bs, η_loss_lines = η_loss_lines, η_loss_source = η_loss_source, ϕ = ϕ,T=T, mode_occ = mode_occ)

interf = build_loop!(params)

i = Input{T}(mode_occ)
ev = Event(i, ThresholdFockDetection(ThresholdModeOccupation([0,0,0,0])), interf)

ev

compute_probability!(ev)

possible_threshold_detections(ev)


all_threshold_mode_occupations(i.n,i.m, only_photon_number_conserving = !is_lossy(interf))

check_full_threshold_distribution(ev)


@test check_full_threshold_distribution(ev)

is_lossy(interf)
interf.m_real
interf.m
!is_lossy(interf)