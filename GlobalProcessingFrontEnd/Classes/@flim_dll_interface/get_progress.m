function [progress, n_completed, cur_group, iter, chi2] = get_progress(obj)

    progress = (obj.fit_round-2+obj.progress) / obj.n_rounds;
    n_completed = obj.progress_n_completed;
    cur_group = obj.progress_cur_group;
    iter = obj.progress_iter;
    chi2 = obj.progress_chi2;

end
