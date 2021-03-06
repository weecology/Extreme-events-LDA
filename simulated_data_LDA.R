# Use simulated data to investigate the results of the LDA model with known dynamics:
#    1. fast transition between 2 topics with steady-state before and after
#    2. slow transition between 2 topics with little to no steady-state before/after
#    3. fixed proportion of 2 topics through time (no transition)


# Started EMC 3/2017

# ====================================================================================
library(multipanelfigure)

source('LDA_figure_scripts.R')
source('AIC_model_selection.R')
source('changepointmodel.r')
source('create_sim_data.R')

cbPalette <- c( "#e19c02","#999999", "#56B4E9", "#0072B2", "#D55E00", "#F0E442", "#009E73", "#CC79A7")

# ==================================================================================
# Create simulated data
# ==================================================================================
#  beta = matrix of species composition of the topics
#  gamma = matrix of prevalence of topics through time


N = 200   # total number of individuals
output = create_sim_data_2topic_nonuniform()

# distribution of species in the sample communities follows a species abundance distribution derived from Portal data (average of sampling periods 1:436)
# the distribution of species in the second sample community is a simple permutation of the first
# the two communities both contain 9 out of 12 species
beta = as.matrix(as.data.frame(output[1]))
colnames(beta) <- list('S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12')

# plot three types of simulated dynamics for the 2 sample communities
gamma_constant = as.matrix(as.data.frame(output[2]))
gamma_fast = as.matrix(as.data.frame(output[3]))
gamma_slow = as.matrix(as.data.frame(output[4]))


# plot beta and gammas
P = plot_community_composition_gg(beta,c(1,2),ylim=c(0,.5),colors=cbPalette[c(2,4)])
(figure_spcomp <- multi_panel_figure(
  width = c(80,80),
  height = c(50,10),
  panel_label_type = "none",
  column_spacing = 0))
figure_spcomp %<>% fill_panel(
  P[[1]],
  row = 1, column = 1)
figure_spcomp %<>% fill_panel(
  P[[2]],
  row = 1, column = 2)
figure_spcomp

sim_dates = seq.Date(from=as.Date('1977-01-01'),by=30,length.out = 400) 

fast = data.frame(date = rep(sim_dates,dim(gamma_fast)[2]),
                  relabund = as.vector(gamma_fast),
                  community = as.factor(c(rep(1,dim(gamma_fast)[1]),rep(2,dim(gamma_fast)[1]))))
slow = data.frame(date = rep(sim_dates,dim(gamma_slow)[2]),
                  relabund = as.vector(gamma_slow),
                  community = as.factor(c(rep(1,dim(gamma_slow)[1]),rep(2,dim(gamma_slow)[1]))))
const = data.frame(date = rep(sim_dates,dim(gamma_constant)[2]),
                   relabund = as.vector(gamma_constant),
                   community = as.factor(c(rep(1,dim(gamma_constant)[1]),rep(2,dim(gamma_constant)[1]))))


g_1 = plot_gamma(fast,2,ylab='Simulated Dynamics',colors=cbPalette[c(2,4)])
g_2 = plot_gamma(slow,2,colors=cbPalette[c(2,4)])
g_3 = plot_gamma(const,2,colors=cbPalette[c(2,4)])
grid.arrange(g_1,g_2,g_3,nrow=1)


# create data sets from beta and gamma; data must be in integer form (simulating species counts)
dataset1 = round(as.data.frame(gamma_fast %*% beta) *N,digits=0)
dataset2 = round(as.data.frame(gamma_slow %*% beta) *N,digits=0)
dataset3 = round(as.data.frame(gamma_constant %*% beta) *N,digits=0)

# ==================================================================
# select number of topics
# ==================================================================

# Fit a bunch of LDA models with different seeds
# Only use even numbers for seeds because consecutive seeds give identical results
seeds = 2*seq(200)

# repeat LDA model fit and AIC calculation with a bunch of different seeds to test robustness of the analysis
best_ntopic_ds1 = repeat_VEM(dataset1,seeds,topic_min=2,topic_max=6)
best_ntopic_ds2 = repeat_VEM(dataset2,seeds,topic_min=2,topic_max=6)
best_ntopic_ds3 = repeat_VEM(dataset3,seeds,topic_min=2,topic_max=6)


 # histogram of how many seeds chose how many topics
hist(best_ntopic_ds1[,2],breaks=c(0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5),xlab='best # of topics', main='')
hist(best_ntopic_ds2[,2],breaks=c(0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5),xlab='best # of topics', main='')
hist(best_ntopic_ds3[,2],breaks=c(0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5),xlab='best # of topics', main='')

# in all three datasets, 2 is the best number of topics

# ==================================================================
# run LDA model
# ==================================================================
SEED  = 1

ldamodel1 = LDA(dataset1,k=2, control = list(seed = SEED),method='VEM')
ldamodel2 = LDA(dataset2,k=2, control = list(seed = SEED),method='VEM')
ldamodel3 = LDA(dataset3,k=2, control = list(seed = SEED),method='VEM')

# plot results - gammas
g1 = plot_component_communities(ldamodel1,2,sim_dates,ylab='LDA model output',colors=cbPalette[c(1,3)])
g2 = plot_component_communities(ldamodel2,2,sim_dates,colors=cbPalette[c(1,3)])
g3 = plot_component_communities(ldamodel3,2,sim_dates,colors=cbPalette[c(1,3)])
grid.arrange(g1,g2,g3,nrow=1)

# plot community compositions (betas)
beta1 = community_composition(ldamodel1)
spcomp_1 = plot_community_composition_gg(beta1,c(2,1),ylim=c(0,.5),colors=cbPalette[c(1,3)])
(figure_spcomp_s1 <- multi_panel_figure(
  width = c(40,40),
  height = c(40,10),
  panel_label_type = "none",
  column_spacing = 0))
figure_spcomp_s1 %<>% fill_panel(
  spcomp_1[[1]],
  row = 1, column = 1)
figure_spcomp_s1 %<>% fill_panel(
  spcomp_1[[2]],
  row = 1, column = 2)
figure_spcomp_s1
plot_community_composition(beta1)


beta2 = community_composition(ldamodel2)
spcomp_2 = plot_community_composition_gg(beta2,c(2,1),ylim=c(0,.5),colors=cbPalette[c(1,3)])
(figure_spcomp_s2 <- multi_panel_figure(
  width = c(40,40),
  height = c(40,10),
  panel_label_type = "none",
  column_spacing = 0))
figure_spcomp_s2 %<>% fill_panel(
  spcomp_2[[1]],
  row = 1, column = 1)
figure_spcomp_s2 %<>% fill_panel(
  spcomp_2[[2]],
  row = 1, column = 2)
#figure_spcomp_s2

beta3 = community_composition(ldamodel3)
spcomp_3 = plot_community_composition_gg(beta3,c(2,1),ylim=c(0,.5),colors=cbPalette[c(1,3)])
(figure_spcomp_s3 <- multi_panel_figure(
  width = c(40,40),
  height = c(40,10),
  panel_label_type = "none",
  column_spacing = 0))
figure_spcomp_s3 %<>% fill_panel(
  spcomp_3[[1]],
  row = 1, column = 1)
figure_spcomp_s3 %<>% fill_panel(
  spcomp_3[[2]],
  row = 1, column = 2)
#figure_spcomp_s3
 
# ==================================================================
# changepoint model 
# ==================================================================
year_continuous_sim = (seq(400)/12) +1977
x_sim = data.frame(
  year_continuous=year_continuous_sim,
  sin_year = sin(year_continuous_sim * 2 * pi),
  cos_year = cos(year_continuous_sim * 2 * pi))

cp_results1 = changepoint_model(ldamodel1, x_sim, 1, weights = rep(1,length(year_continuous_sim)))
cp_results2 = changepoint_model(ldamodel2, x_sim, 1, weights = rep(1,length(year_continuous_sim)))
cp_results3 = changepoint_model(ldamodel3, x_sim, 1, weights = rep(1,length(year_continuous_sim)))

# changepoint visualizations
par(mfrow=c(1,3))
annual_hist(cp_results1,year_continuous_sim)
annual_hist(cp_results2,year_continuous_sim)
annual_hist(cp_results3,year_continuous_sim)
par(mfrow=c(1,1))

dfsim1 = data.frame(value = year_continuous_sim[cp_results1$saved[,1,]])
H_sim1 = ggplot(data = dfsim1, aes(x=value)) +
  geom_histogram(data=dfsim1,aes(y=..count../sum(..count..)),binwidth = .5,fill='black') +
  labs(x='',y='Changepoint Model') +
  ylim(c(0,1)) +
  xlim(range(year_continuous_sim)) +
  theme(axis.text=element_text(size=9),
        panel.border=element_rect(colour='black',fill=NA))
dfsim2 = data.frame(value = year_continuous_sim[cp_results2$saved[,1,]])
H_sim2 = ggplot(data = dfsim2, aes(x=value)) +
  geom_histogram(data=dfsim2,aes(y=..count../sum(..count..)),binwidth = .5,fill='black') +
  labs(x='',y='') +
  ylim(c(0,1)) +
  xlim(range(year_continuous_sim)) +
  theme(axis.text=element_text(size=9),
        panel.border=element_rect(colour='black',fill=NA))
dfsim3 = data.frame(value = year_continuous_sim[cp_results3$saved[,1,]])
H_sim3 = ggplot(data = dfsim3, aes(x=value)) +
  geom_histogram(data=dfsim3,aes(y=..count../sum(..count..)),binwidth = .5,fill='black') +
  labs(x='',y='') +
  ylim(c(0,1)) +
  xlim(range(year_continuous_sim)) +
  theme(axis.text=element_text(size=9),
        panel.border=element_rect(colour='black',fill=NA))

# ===============================================================
# Create Figure
# ===============================================================

# all in one big multipart figure
(figure <- multi_panel_figure(
  width = c(40,40,40,40,40,40),
  height = c(35,40,40,40,40),
  panel_label_type = "lower-alpha"))
figure %<>% fill_panel(
  figure_spcomp,
  row = 1, column = 2:5)
figure %<>% fill_panel(
  g_1,
  row = 2, column = 1:2)
figure %<>% fill_panel(
  g_2,
  row = 2, column = 3:4)
figure %<>% fill_panel(
  g_3,
  row = 2, column = 5:6)
figure %<>% fill_panel(
  figure_spcomp_s1,
  row = 3, column = 1:2)
figure %<>% fill_panel(
  figure_spcomp_s2,
  row = 3, column = 3:4)
figure %<>% fill_panel(
  figure_spcomp_s3,
  row = 3, column = 5:6)
figure %<>% fill_panel(
  g1,
  row = 4, column = 1:2)
figure %<>% fill_panel(
  g2,
  row = 4, column = 3:4)
figure %<>% fill_panel(
  g3,
  row = 4, column = 5:6)
figure %<>% fill_panel(
  H_sim1,
  row = 5, column = 1:2)
figure %<>% fill_panel(
  H_sim2,
  row = 5, column = 3:4)
figure %<>% fill_panel(
  H_sim3,
  row = 5, column = 5:6)

figure

# separate figures for model inputs and model outputs
(figure_inputs <- multi_panel_figure(
  width = c(40,40,40,40,40,40),
  height = c(35,10,40)))
figure_inputs %<>% fill_panel(
  figure_spcomp,
  row = 1, column = 2:5)
figure_inputs %<>% fill_panel(
  g_1,
  row = 3, column = 1:2)
figure_inputs %<>% fill_panel(
  g_2,
  row = 3, column = 3:4)
figure_inputs %<>% fill_panel(
  g_3,
  row = 3, column = 5:6)
figure_inputs

(figure_outputs <- multi_panel_figure(
  width = c(40,40,40,40,40,40),
  height = c(40,40,40)))
figure_outputs %<>% fill_panel(
  figure_spcomp_s1,
  row = 1, column = 1:2)
figure_outputs %<>% fill_panel(
  figure_spcomp_s2,
  row = 1, column = 3:4)
figure_outputs %<>% fill_panel(
  figure_spcomp_s3,
  row = 1, column = 5:6)
figure_outputs %<>% fill_panel(
  g1,
  row = 2, column = 1:2)
figure_outputs %<>% fill_panel(
  g2,
  row = 2, column = 3:4)
figure_outputs %<>% fill_panel(
  g3,
  row = 2, column = 5:6)
figure_outputs %<>% fill_panel(
  H_sim1,
  row = 3, column = 1:2)
figure_outputs %<>% fill_panel(
  H_sim2,
  row = 3, column = 3:4)
figure_outputs %<>% fill_panel(
  H_sim3,
  row = 3, column = 5:6)

figure_outputs
