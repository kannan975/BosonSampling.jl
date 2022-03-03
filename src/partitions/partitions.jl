### in this file we compute the probabilities to find
# photons in partitions of the output modes
# a partition is a set of subsets of the output modes

function all_mode_configurations(n,n_subset; only_photon_number_conserving = false)

        """generates all possible photon counts
        of n photons in a partition/subset
        of n_subset subsets

        does not take into account photon number conservation by default

        this is the photon counting in partitions and not events outputs

        but it can be used likewise"""

        array = []
        for i in 1:(n+1)^(n_subset)

                this_vector = digits(i-1, base = n+1, pad = n_subset)

                if only_photon_number_conserving
                        if sum(this_vector) == n
                                push!(array,this_vector)
                        end
                else
                        push!(array,this_vector)
                end

        end
        array

end

all_mode_configurations(input_state::Input,part::Partition; only_photon_number_conserving = false) = all_mode_configurations(input_state.n,part.n_subset; only_photon_number_conserving = only_photon_number_conserving)

all_mode_configurations(input_state::Input,sub::Subset; only_photon_number_conserving = false) = all_mode_configurations(input_state.n,1; only_photon_number_conserving = only_photon_number_conserving)

function photon_number_conserving_events(physical_indexes, n; partition_spans_all_modes = false)

        """returns only the events conserving photon number n

        if partition_spans_all_modes = false, gives all events with less than n or n
        photons

        if partition_spans_all_modes = true only exact photon number conserving
        physical_indexes"""

        results = []
        for index in physical_indexes
                if partition_spans_all_modes == false
                        if sum(index) <= n
                                push!(results, index)
                        end
                else
                        if sum(index) == n
                                push!(results, index)
                        end
                end
        end
        results

end


function photon_number_non_conserving_events(physical_indexes,n ; partition_spans_all_modes = false)

        """returns the elements not conserving the number of photons"""

        setdiff(physical_indexes, photon_number_conserving_events(physical_indexes, n, ; partition_spans_all_modes = partition_spans_all_modes))

end

function check_photon_conservation(physical_indexes,  pdf, n; atol = ATOL, partition_spans_all_modes = false)

        """checks if probabilities corresponding to non photon number conserving
        events are zero"""

        events_to_check = photon_number_non_conserving_events(physical_indexes,n; partition_spans_all_modes = partition_spans_all_modes)

        for (i, index) in enumerate(physical_indexes)
                if index in events_to_check
                        @argcheck isapprox(clean_proba(pdf[i]),0, atol=atol)# "forbidden event has non zero probability"
                end
        end

end

function compute_probabilities_partition(physical_interferometer::Interferometer, part::Partition, input_state::Input)

        """computes the probability to find a certain photon counts in a
        partition `part` of the output modes for the interferometer given

        returns : (counts = physical_indexes, probabilities = pdf)

        corresponding to the occupation numbers in the partition and the
        associated probability"""

        @argcheck at_most_one_photon_per_bin(input_state) "more than one input per mode is not implemented"

        occupies_all_modes(part) ? (@warn "inefficient if no loss: partition occupies all modes thus extra calculations made that are unnecessary") : nothing

        n = input_state.n
        m = input_state.m
        mode_occupation_list = fill_arrangement(input_state)
        S = input_state.G.S

        fourier_indexes = all_mode_configurations(n,part.n_subset, only_photon_number_conserving = false)
        probas_fourier = Array{ComplexF64}(undef, length(fourier_indexes))
        virtual_interferometer_matrix = similar(physical_interferometer.U)

        for (index_fourier_array, fourier_index) in enumerate(fourier_indexes)

                # for each fourier index, we recompute the virtual interferometer
                virtual_interferometer_matrix  = physical_interferometer.U
                diag = [one(eltype(virtual_interferometer_matrix)) for i in 1:m]

                for (i,fourier_element) in enumerate(fourier_index)

                        this_phase = exp(2*pi*1im/(n+1) * fourier_element)

                        for j in 1:length(diag)

                                if part.subsets[i].subset[j] == 1
                                        diag[j] *= this_phase

                                end

                        end

                end

                virtual_interferometer_matrix *= Diagonal(diag)
                virtual_interferometer_matrix *= physical_interferometer.U'


                # beware, only the modes corresponding to the
                # virtual_interferometer_matrix[input_config,input_config]
                # must be taken into account !
                probas_fourier[index_fourier_array] = permanent(virtual_interferometer_matrix[mode_occupation_list,mode_occupation_list] .* S)
        end

        physical_indexes = copy(fourier_indexes)

        probas_physical(physical_index) = 1/(n+1)^(part.n_subset) * sum(probas_fourier[i] * exp(-2pi*1im/(n+1) * dot(physical_index, fourier_index)) for (i,fourier_index) in enumerate(fourier_indexes))


        pdf = [probas_physical(physical_index) for physical_index in physical_indexes]

        pdf = clean_pdf(pdf)

        check_photon_conservation(physical_indexes, pdf, n; partition_spans_all_modes = occupies_all_modes(part))

        (physical_indexes, pdf)
end

function compute_probability_partition_occupancy(physical_interferometer::Interferometer, part_occupancy::PartitionOccupancy, input_state::Input)

        """computes the probability to find a partition occupancy

        note: inefficient to use multiple times for the same physical setting,
        rather use compute_probabilities_partition"""

        (physical_indexes, pdf) = compute_probabilities_partition(physical_interferometer, part_occupancy.partition, input_state::Input)

        for (i,counts) in enumerate(physical_indexes)
                if counts == part_occupancy.counts.state
                        return pdf[i]
                end
        end
        nothing

end

function print_pdfs(physical_indexes, pdf, n; physical_events_only = false, partition_spans_all_modes = false)

        indexes_to_print = physical_events_only ? photon_number_conserving_events(physical_indexes, n; partition_spans_all_modes = partition_spans_all_modes) : physical_indexes

        println("---------------")
        println("Partition results : ")
        for (i, index) in enumerate(physical_indexes)
                if index in indexes_to_print
                        println("index = $index, p = $(pdf[i])")
                end

        end
        println("---------------")
end

function compute_probability!(ev::Event{TIn,TOut}) where {TIn<:InputType, TOut<:PartitionCount}

        check_probability_empty(ev)

        ev.proba_params.precision = eps()
        ev.proba_params.failure_probability = 0

        ev.proba_params.probability = compute_probability_partition_occupancy(ev.interferometer, ev.part_occupancy, ev.input_state)

end

function compute_probability!(ev::Event{TIn,TOut}) where {TIn<:InputType, TOut<:PartitionCountsAll}

        check_probability_empty(ev)

        ev.proba_params.precision = eps()
        ev.proba_params.failure_probability = 0

        # ev.proba_params.probability = compute_probability_partition_occupancy(ev.interferometer, ev.part_occupancy, ev.input_state)

end


#
# check_probability_empty(ev)
#
# interf = ev.interferometer
# part = ev.output_measurement.part_occupancy
# input_state = ev.input_state
#
# ev.proba_params.precision = eps()
# ev.proba_params.failure_probability = 0
#
# ev.proba_params.probability = nothing ####################33compute_probabilities_partition(ev.interferometer, ev.part::Partition, input_state::Input)
