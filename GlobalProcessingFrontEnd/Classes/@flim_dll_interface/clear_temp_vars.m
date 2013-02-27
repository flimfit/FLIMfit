function clear_temp_vars(obj)

    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren




    clear obj.p_t obj.p_mask obj.p_tau_guess obj.p_tau_min obj.p_tau_max 
    clear obj.p_irf obj.p_t_irf obj.p_t0_image obj.p_n_regions  obj.p_fixed_beta obj.n_group
    clear obj.p_E_guess obj.p_tau obj.p_beta obj.p_E obj.p_gamma obj.p_I0 obj.p_global_beta_group
    clear obj.p_t0 obj.p_offset obj.p_scatter obj.p_chi2 obj.p_ierr obj.p_use
    clear obj.p_acceptor
end