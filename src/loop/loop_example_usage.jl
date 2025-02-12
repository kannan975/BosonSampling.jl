include("packages_loop.jl")


# note: just go to the bottom for a minimum usage, the first two blocks are kept as intermediary building blocks to this abstract usage for debugging purposes

begin
    ### 2d HOM without loss but with ModeList example ###

    n = 2
    m = 2
    i = Input{Bosonic}(first_modes(n,m))
    o = FockDetection(ModeOccupation([1,1])) # detecting bunching, should be 0.5 in probability if there was no loss
    transmission_amplitude_loss_array = 0:0.1:1
    output_proba = []

    circuit = LosslessCircuit(2)
    interf = BeamSplitter(1/sqrt(2))
    target_modes = ModeList([1,2], m)

    add_element!(circuit, interf, target_modes)

    ev = Event(i,o, circuit)
    compute_probability!(ev)

    ### one d ex ##

    n = 1
    m = 1

    function lossy_line_example(η_loss)

        circuit = LossyCircuit(1)
        interf = LossyLine(η_loss)
        target_modes = ModeList([1],m)

        add_element_lossy!(circuit, interf, target_modes)
        circuit

    end

    lossy_line_example(0.9)

    transmission_amplitude_loss_array = 0:0.1:1
    output_proba = []

    i = Input{Bosonic}(to_lossy(first_modes(n,m)))
    o = FockDetection(to_lossy(first_modes(n,m)))

    for transmission in transmission_amplitude_loss_array

        ev = Event(i,o, lossy_line_example(transmission))
        @show compute_probability!(ev)
        push!(output_proba, ev.proba_params.probability)
    end

    print(output_proba)

    plot(transmission_amplitude_loss_array, output_proba)
    ylabel!("p no lost")
    xlabel!("transmission amplitude")

    ### the same with autoconversion of the input and output dimensions ###

    i = Input{Bosonic}(first_modes(n,m))
    o = FockDetection(first_modes(n,m))

    for transmission in transmission_amplitude_loss_array

        ev = Event(i,o, lossy_line_example(transmission))
        @show compute_probability!(ev)
        push!(output_proba, ev.proba_params.probability)
    end


    ### 2d HOM with loss example ###

    n = 2
    m = 2
    i = Input{Bosonic}(first_modes(n,m))
    o = FockDetection(ModeOccupation([2,0])) # detecting bunching, should be 0.5 in probability if there was no loss
    transmission_amplitude_loss_array = 0:0.1:1
    output_proba = []

    function lossy_bs_example(η_loss)

        circuit = LossyCircuit(2)
        interf = LossyBeamSplitter(1/sqrt(2), η_loss)
        target_modes = ModeList([1,2],m)

        add_element_lossy!(circuit, interf, target_modes)
        circuit

    end

    for transmission in transmission_amplitude_loss_array

        ev = Event(i,o, lossy_bs_example(transmission))
        compute_probability!(ev)
        push!(output_proba, ev.proba_params.probability)
    end

    @test output_proba ≈ [0.0, 5.0000000000000016e-5, 0.0008000000000000003, 0.004049999999999998, 0.012800000000000004, 0.031249999999999993, 0.06479999999999997, 0.12004999999999996, 0.20480000000000007, 0.32805, 0.4999999999999999]


    ### building the loop ###

    n = 3
    m = n

    i = Input{Bosonic}(first_modes(n,m))

    η = 1/sqrt(2) .* ones(m-1)
    # 1/sqrt(2) .* [1,0] #ones(m-1) # see selection of target_modes = [i, i+1] for m-1
    # [1/sqrt(2), 1] #1/sqrt(2) .* ones(m-1) # see selection of target_modes = [i, i+1] for m-1

    η_loss = 1. .* ones(m-1)

    circuit = LosslessCircuit(m)

    for mode in 1:m-1

        interf = BeamSplitter(η[mode])#LossyBeamSplitter(η[mode], η_loss[mode])
        #target_modes_in = ModeList([mode, mode+1], circuit.m_real)
        #target_modes_out = ModeList([mode, mode+1], circuit.m_real)

        target_modes_in = ModeList([mode, mode+1], m)
        target_modes_out = target_modes_in
        add_element!(circuit, interf, target_modes_in, target_modes_out)

    end


    ############## lossy_target_modes needs to be changed, it need to take into account the size of the circuit rather than that of the target modes


    #outputs compatible with two photons top mode
    o1 = FockDetection(ModeOccupation([2,1,0]))
    o2 = FockDetection(ModeOccupation([2,0,1]))

    o_array = [o1,o2]

    p_two_photon_first_mode = 0

    for o in o_array
        ev = Event(i,o, circuit)
        @show compute_probability!(ev)
        p_two_photon_first_mode += ev.proba_params.probability
    end

    p_two_photon_first_mode

    o3 = FockDetection(ModeOccupation([3,0,0]))
    ev = Event(i,o3, circuit)
    @show compute_probability!(ev)

    ### loop with loss and types ###

    begin
        n = 3
        m = n

        i = Input{Bosonic}(first_modes(n,m))

        η = 1/sqrt(2) .* ones(m-1)
        η_loss_bs = 0.9 .* ones(m-1)
        η_loss_lines = 0.9 .* ones(m)
        d = Uniform(0, 2pi)
        ϕ = rand(d, m)

    end

    circuit = LossyLoop(m, η, η_loss_bs, η_loss_lines, ϕ).circuit

    o1 = FockDetection(ModeOccupation([2,1,0]))
    o2 = FockDetection(ModeOccupation([2,0,1]))

    o_array = [o1,o2]

    p_two_photon_first_mode = 0

    for o in o_array
        ev = Event(i,o, circuit)
        @show compute_probability!(ev)
        p_two_photon_first_mode += ev.proba_params.probability
    end

    p_two_photon_first_mode

    o3 = FockDetection(ModeOccupation([3,0,0]))
    ev = Event(i,o3, circuit)
    @show compute_probability!(ev)

     Event(i,o3, circuit)
    compute_probability!(ev)

end

begin

    ### sampling ###
    begin
        n = 3
        m = n

        i = Input{Bosonic}(first_modes(n,m))

        η = 1/sqrt(2) .* ones(m-1)
        η_loss_bs = 0.9 .* ones(m-1)
        η_loss_lines = 0.9 .* ones(m)
        d = Uniform(0, 2pi)
        ϕ = rand(d, m)

    end

    circuit = LossyLoop(m, η, η_loss_bs, η_loss_lines, ϕ).circuit


    p_dark = 0.01
    p_no_count = 0.1

    o = FockSample()
    ev = Event(i,o, circuit)

    BosonSampling.sample!(ev)

    o = DarkCountFockSample(p_dark)
    ev = Event(i,o, circuit)

    BosonSampling.sample!(ev)

    o = RealisticDetectorsFockSample(p_dark, p_no_count)
    ev = Event(i,o, circuit)

    BosonSampling.sample!(ev)

end

###### sample with a new circuit each time ######

# have a look at the documentation for the parameters and functions


get_sample_loop(LoopSamplingParameters(n = 10, input_type = Distinguishable))


build_loop(LoopSamplingParameters(n = 10, input_type = Distinguishable))

### partitions ###

params = PartitionSamplingParameters(n = 10, m = 10)

compute_probability!(params)

### computing the entire distribution ###

n = 3
interf = Fourier(n)
o = BosonSamplingDistribution()

params = SamplingParameters(n = n, interf = interf, o = o)

set_parameters!(params)

compute_probability!(params.ev)
compute_probability!(params)

### imperfect sources and summing all possible probabilities ###

n = 3
m = n

d = Uniform(0,2pi)
ϕ = nothing # rand(d,m)
η_loss_lines = 0.9 * ones(m)
η_loss_bs = 1. * ones(m-1)

params = LoopSamplingParameters(n=n, η = η_thermalization(n), η_loss_bs = η_loss_bs, η_loss_lines = η_loss_lines, ϕ = ϕ)

source = QuantumDot(efficiency = 0.85)

params_event = convert(SamplingParameters, params)
params_event_x = copy(params_event)

params_event_x.x = 0

params_event.o =  FockDetection(ModeOccupation([1,1,0]))
params_event_x.o =  FockDetection(ModeOccupation([1,1,0]))

set_parameters!(params_event)
set_parameters!(params_event_x)

compute_probability_imperfect_source(params_event, source)
compute_probability_imperfect_source(params_event_x, source)


p_x_imperfect_source(params_event, 0, source)

ev = params_event_x.ev
ev.output_measurement = FockDetection(ModeOccupation([1,1,1]))
ev

p_x_imperfect_source_update_this_event(ev, params_event_x, source)


### computing ThresholdFockDetection event probabilities ###


n = 4
m = n

d = Uniform(0,2pi)
ϕ = nothing # rand(d,m)
η_loss_lines = nothing #0.2 * ones(m)
η_loss_bs = nothing # 0.2 * ones(m-1)

params = LoopSamplingParameters(n=n, η = η_thermalization(n), η_loss_bs = η_loss_bs, η_loss_lines = η_loss_lines, ϕ = ϕ)

params_event = convert(SamplingParameters, params)
params_event.o = ThresholdFockDetection(ThresholdModeOccupation([0,0,1,1]))

set_parameters!(params_event)

ev = params_event.ev

@test compute_threshold_detection_probability(ev) ≈ 0.21782756693593455

# now adding some loss 

η_loss_lines = 0.2 * ones(m)
η_loss_bs =  0.2 * ones(m-1)

params = LoopSamplingParameters(n=n, η = η_thermalization(n), η_loss_bs = η_loss_bs, η_loss_lines = η_loss_lines, ϕ = ϕ)

params_event = convert(SamplingParameters, params)
params_event.o = ThresholdFockDetection(ThresholdModeOccupation([0,0,1,1]))

set_parameters!(params_event)

ev = params_event.ev

@test compute_threshold_detection_probability(ev) ≈ 0.06234128207801644

# can also just use 

@test compute_probability!(params_event) ≈ 0.06234128207801644