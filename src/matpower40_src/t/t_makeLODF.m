function t_makeLODF(quiet)
%T_MAKELODF  Tests for MAKELODF.

%   MATPOWER
%   $Id: t_makeLODF.m 4738 2014-07-03 00:55:39Z dchassin $
%   by Ray Zimmerman, PSERC Cornell
%   Copyright (c) 2008-2010 by Power System Engineering Research Center (PSERC)
%
%   This file is part of MATPOWER.
%   See http://www.pserc.cornell.edu/matpower/ for more info.
%
%   MATPOWER is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published
%   by the Free Software Foundation, either version 3 of the License,
%   or (at your option) any later version.
%
%   MATPOWER is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with MATPOWER. If not, see <http://www.gnu.org/licenses/>.
%
%   Additional permission under GNU GPL version 3 section 7
%
%   If you modify MATPOWER, or any covered work, to interface with
%   other modules (such as MATLAB code and MEX-files) available in a
%   MATLAB(R) or comparable environment containing parts covered
%   under other licensing terms, the licensors of MATPOWER grant
%   you additional permission to convey the resulting work.

if nargin < 1
    quiet = 0;
end

ntests = 31;
t_begin(ntests, quiet);

casefile = 't_auction_case';
if quiet
    verbose = 0;
else
    verbose = 0;
end

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

%% load case
mpc = loadcase(casefile);
mpopt = mpoption('OUT_ALL', 0, 'VERBOSE', verbose);
[baseMVA, bus, gen, gencost, branch, f, success, et] = ...
    rundcopf(mpc, mpopt);
[i2e, bus, gen, branch] = ext2int(bus, gen, branch);

%% compute injections and flows
F0  = branch(:, PF);

%% create some PTDF matrices
H  = makePTDF(baseMVA, bus, branch, 1);

%% create some PTDF matrices
s = warning('query', 'MATLAB:divideByZero');
warning('off', 'MATLAB:divideByZero');
LODF = makeLODF(branch, H);
warning(s.state, 'MATLAB:divideByZero');

%% take out non-essential lines one-by-one and see what happens
mpc.bus = bus;
mpc.gen = gen;
branch0 = branch;
outages = [1:12 14:15 17:18 20 27:33 35:41];
for k = outages
    mpc.branch = branch0;
    mpc.branch(k, BR_STATUS) = 0;
    [baseMVA, bus, gen, branch, success, et] = rundcpf(mpc, mpopt);
    F = branch(:, PF);

    t_is(LODF(:, k), (F - F0) / F0(k), 6, sprintf('LODF(:, %d)', k));
end

t_end;
