function clear_temp_vars(obj)
    clear obj.p_t obj.p_mask obj.p_tau_guess obj.p_tau_min obj.p_tau_max 
    clear obj.p_irf obj.p_t_irf obj.p_t0_image obj.p_n_regions  obj.p_fixed_beta obj.n_group
    clear obj.p_E_guess obj.p_tau obj.p_beta obj.p_E obj.p_gamma obj.p_I0 obj.p_global_beta_group
    clear obj.p_t0 obj.p_offset obj.p_scatter obj.p_chi2 obj.p_ierr obj.p_use
end