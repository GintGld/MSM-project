classdef testTransitionMatrix < matlab.unittest.TestCase
    methods (Test)
        function testMonteCarloApproximation(testCase)

            % Random weights
            W = rand(5,1);

            disp(W);

            % Exact matrix
            M_exact = build_markov_explicit(W);

            % Monte Carlo approximate matrix
            M_mc = build_monte_carlo(W, 1e8);

            % Tolerance due to randomness
            tol = 5e-2;

            disp(M_exact);

            disp(M_mc);

            % Verify each entry is close
            testCase.verifyLessThan( abs(M_exact - M_mc), tol, ...
                "Matrix entries differ by more than tolerance");

            % Optional: verify row-stochasticity
            testCase.verifyLessThan( abs(sum(M_mc,2) - 1), 1e-6, ...
                "Monte Carlo transition matrix rows must sum to 1");
        end
    end
end
