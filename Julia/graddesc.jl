# graddesc.jl
module GradDesc

using InfDecomp_Base





struct Solution_Stats
    optimum     :: Float64
    q           :: Vector{Float64}
    time        :: Float64
end



export GD_Params, GD_Results, prj_graddesc, fw_graddesc


struct IPGD_Params
    ...
end

struct IPGD_Results{FLOAT}
    ...
end

using InfDecomp.My_Eval

function GD_container{FLOAT}(e::My_Eval, param::IPGD_Params, dummy::FLOAT) :: IPGD_Results{FLOAT}
    oldprc = precision(BigFloat)
    setprecision(BigFloat,e.bigfloat_nbits)

    r = interior_projected_gdescent(e,param, dummy)

    setprecision(BigFloat,oldprc)

    return r;
end

# Function oracles

f(q::FLOAT) :: FLOAT = -InfDecomp.condEntropy(e,q,FLOAT())

# Projection

struct Projector_Data{FLOAT}
    ...
end

function setup_prj!{FLOAT}(prjdata::Projector_Data{FLOAT}, e::My_Eval) :: Void

    ...

    return nothing;
end

function prj!{FLOAT}(y::Vector{FLOAT}, x::Vector{FLOAT}, prjd::Projector_Data{FLOAT}) :: Void

    ...

    return nothing;
end



function interior_projected_gdescent{FLOAT}(e::My_Eval, param::IPGD_Params, dummy::FLOAT) :: IPGD_Results{FLOAT}

    local prjdata :: Projector_DATA{FLOAT}
    setup_prj!(prjdata, e,param)

    local q   = Vector{FLOAT}( Ones(e.n)  )  # current feasible solution
    local ∇   = Vector{FLOAT}( zeros(e.n) )  # gradient
    local pr∇ = Vector{FLOAT}( zeros(e.n) )  # projected gradient
    local x   = Vector{FLOAT}( zeros(e.n) )  # q + pr∇
    local δ   = FLOAT(1)/(e.n_x*100)         # distance from boundary
    local η   = δ                            # step length

    local terminate::Bool

    local iter = 1
    while (true)
        print(iter,":  f=",f(q))

        # Compute gradient
        InfDecomp.∇f(e, ∇, q, FLOAT(0))

        # Project gradient
        prj!(pr∇, ∇, prjdata)

        # Check if projected gradient is nearly 0 (= terminate)
        nm_1 = norm(pr∇,1.)
        nm_2 = norm(pr∇,2.)
        nm_∞ = norm(pr∇,Inf)

        print(" |pr∇|_1=",nm_1," |pr∇|_2=",nm_2," |pr∇|_∞=",nm_∞)

        if nm_infty > 1.e100

            # Find intersection with boundary
            local γ = FLOAT(1.e300) # init to infty
            for y = 1:e.n_y
                for z = 1:e.n_z
                    # make marginal q(*yz) and pr∇(*yz)
                    Q_yz::FLOAT   = FLOAT(0)
                    pr∇_yz::FLOAT = FLOAT(0)
                    for x = 1:e.n_x
                        i = e.varidx[x,y,z]
                        if i>0
                            Q_yz   += q[i]
                            pr∇_yz += ∇[i]
                        end
                    end
                    # check them
                    for x = 1:e.n_x
                        i = e.varidx[x,y,z]
                        if i>0
                            local β = pr∇[i] - δ*pr∇_yz
                            if β<0
                                γ = min( γ ,   -( q[i] - δ*Q_yz )/β )
                            end
                        end
                    end
                end# for y
            end# for x


            if η > γ
                # we're fine, make the step of length η
                print(" η=",η," > γ=",γ)
                q .+= η .* pr∇
            elseif
                # make a step of length γ; update boundary distance and default step length
                print(" η=",η," > γ=",γ)
                q .+= γ .* pr∇
                δ /= 2
                η /= 4
                print(" new η=",η,", δ=",δ)

                if δ < 1.e300
                    print(" δ TINY")
                    terminate = true
            end
        else
            print(" ORTHOGONAL GRADIENT")
            terminate = true
        end

        if (iter > 10000)
            print(" MAX ITER")
            terminate = true
        end

        if  terminate
            print(" -- TERMINATE")
        else
            print("\n")
        end
    end


    ;
end


end # module
