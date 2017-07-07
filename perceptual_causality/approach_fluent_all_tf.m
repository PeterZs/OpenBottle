
addpath(genpath('/home/mark/Dropbox/Developer/matlab'));

approach_cell_mat = csv2cell('/home/mark/Desktop/actions/approach.csv', 'fromfile');

[data, tf_ordering] = extract_data_from_cell(approach_cell_mat);

poses = data(:, 1:size(data,2) - 26);
forces = data(:, size(data,2) - 25:size(data,2));

loop_cnt = 1;
num_bins = 20;
num_tfs = size(tf_ordering,2)/2;
rel_dist_pre = zeros(num_tfs, size(poses,1)/2);
rel_dist_post = zeros(num_tfs, size(poses,1)/2);
edges = zeros(num_tfs, num_bins+1);
pre_counts = zeros(num_tfs, num_bins);
post_counts = zeros(num_tfs, num_bins);
pre_pd = zeros(num_tfs, num_bins);
post_pd = zeros(num_tfs, num_bins);
kl_div = zeros(num_bins,1);

figure();
for i=1:7:size(poses,2)

  prewindows = poses(1:2:size(poses,1),i:i+6);
  postwindows = poses(2:2:size(poses,1),i:i+6);

  x_pre = prewindows(:,1);
  y_pre = prewindows(:,2);
  z_pre = prewindows(:,3);
  x_post = postwindows(:,1);
  y_post = postwindows(:,2);
  z_post = postwindows(:,3);

  % compute the relative distance between the wrist and the bottle
  rel_dist_pre(loop_cnt,:) = dist_fluent(x_pre, y_pre, z_pre);
  rel_dist_post(loop_cnt,:) = dist_fluent(x_post, y_post, z_post);
  
  % compute and plot histogram
  edges(loop_cnt, :) = linspace(min(min(rel_dist_pre(loop_cnt,:)), min(rel_dist_post(loop_cnt,:))), ...
                                max(max(rel_dist_pre(loop_cnt,:)), max(rel_dist_post(loop_cnt,:))), num_bins+1);
  subplot(4,5,loop_cnt); 
  hold on;
  h_pre = histogram(rel_dist_pre, edges(loop_cnt, :), 'EdgeColor', 'none', 'FaceColor', 'blue');
  h_post = histogram(rel_dist_post, edges(loop_cnt, :), 'EdgeColor', 'none', 'FaceColor', 'red');
  pre_counts(loop_cnt, :) = h_pre.Values;
  post_counts(loop_cnt, :) = h_post.Values;
  
  
  % compute distributions
  eps_ = 0.0001;
  pre_pd(loop_cnt, :) = (pre_counts(loop_cnt,:) - min(pre_counts(loop_cnt,:))) / (max(pre_counts(loop_cnt,:)) - min(pre_counts(loop_cnt,:)));
  post_pd(loop_cnt, :) = (post_counts(loop_cnt,:) - min(post_counts(loop_cnt,:))) / (max(post_counts(loop_cnt,:)) - min(post_counts(loop_cnt,:)));
  pre_pd(loop_cnt, find(pre_pd(loop_cnt,:) == 0)) = eps_;
  post_pd(loop_cnt, find(post_pd(loop_cnt,:) == 0)) = eps_;
  
  % kl_div = KLDiv(pre_dist, post_dist);
  kl_div(loop_cnt) = sum(pre_pd(loop_cnt,:) .* (log2(pre_pd(loop_cnt,:)) - log2(post_pd(loop_cnt,:))));
  frame_id = strrep(tf_ordering(1,(loop_cnt-1)*2+1),'_','\_');
  child_frame_id = strrep(tf_ordering(1,(loop_cnt-1)*2+2),'_','\_');
  title(sprintf('%s ->\n %s \n KL: %f', frame_id{1}, child_frame_id{1}, kl_div(loop_cnt)), 'FontSize',7, 'FontWeight', 'normal');
  
  loop_cnt = loop_cnt + 1;
  hold off;
end