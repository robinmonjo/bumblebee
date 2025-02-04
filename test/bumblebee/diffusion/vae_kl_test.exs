defmodule Bumblebee.Diffusion.VaeKlTest do
  use ExUnit.Case, async: true

  import Bumblebee.TestHelpers

  @moduletag model_test_tags()

  test ":base" do
    assert {:ok, %{model: model, params: params, spec: spec}} =
             Bumblebee.load_model(
               {:hf, "hf-internal-testing/tiny-stable-diffusion-torch", subdir: "vae"},
               params_filename: "diffusion_pytorch_model.bin"
             )

    assert %Bumblebee.Diffusion.VaeKl{architecture: :base} = spec

    inputs = %{
      "sample" => Nx.broadcast(0.5, {1, 32, 32, 3})
    }

    outputs = Axon.predict(model, params, inputs)

    assert Nx.shape(outputs.sample) == {1, 32, 32, 3}

    assert_all_close(
      to_channels_first(outputs.sample)[[.., .., 1..3, 1..3]],
      Nx.tensor([
        [
          [[0.0164, -0.1439, 0.4768], [0.3165, 0.0599, 0.1729], [0.1148, 0.5428, 0.6126]],
          [[0.3587, 0.4221, 0.1088], [0.4741, 0.4139, 0.6284], [0.4739, 0.1454, 0.3089]],
          [[-0.2398, 0.2247, -0.2082], [-0.1440, 0.0256, -0.0120], [-0.0982, -0.3666, -0.1221]]
        ]
      ]),
      atol: 1.0e-4
    )
  end

  test ":decoder" do
    assert {:ok, %{model: model, params: params, spec: spec}} =
             Bumblebee.load_model(
               {:hf, "hf-internal-testing/tiny-stable-diffusion-torch", subdir: "vae"},
               architecture: :decoder,
               params_filename: "diffusion_pytorch_model.bin"
             )

    assert %Bumblebee.Diffusion.VaeKl{architecture: :decoder} = spec

    inputs = %{
      "sample" => Nx.broadcast(0.5, {1, 16, 16, 4})
    }

    outputs = Axon.predict(model, params, inputs)

    assert Nx.shape(outputs.sample) == {1, 32, 32, 3}

    assert_all_close(
      to_channels_first(outputs.sample)[[.., .., 1..3, 1..3]],
      Nx.tensor([
        [
          [[-0.1682, -0.1015, -0.4158], [-0.4621, 0.5176, -0.0999], [-0.0685, 0.7141, 0.3287]],
          [[-0.6000, -0.0538, -0.6703], [0.4113, 0.3203, -0.5005], [0.2073, -0.1205, 0.2487]],
          [[0.2776, 0.6985, 0.2960], [0.4759, -0.3528, -0.7306], [0.5656, -0.5858, -0.2490]]
        ]
      ]),
      atol: 1.0e-4
    )
  end

  test ":encoder" do
    assert {:ok, %{model: model, params: params, spec: spec}} =
             Bumblebee.load_model(
               {:hf, "hf-internal-testing/tiny-stable-diffusion-torch", subdir: "vae"},
               architecture: :encoder,
               params_filename: "diffusion_pytorch_model.bin"
             )

    assert %Bumblebee.Diffusion.VaeKl{architecture: :encoder} = spec

    inputs = %{
      "sample" => Nx.broadcast(0.5, {1, 32, 32, 3})
    }

    outputs = Axon.predict(model, params, inputs)

    assert Nx.shape(outputs.latent_dist.mean) == {1, 16, 16, 4}
    assert Nx.shape(outputs.latent_dist.var) == {1, 16, 16, 4}
    assert Nx.shape(outputs.latent_dist.logvar) == {1, 16, 16, 4}
    assert Nx.shape(outputs.latent_dist.std) == {1, 16, 16, 4}

    assert_all_close(
      to_channels_first(outputs.latent_dist.mean)[[.., 1..3, 1..3, 1..3]],
      Nx.tensor([
        [
          [[0.1788, 0.2526, 0.3464], [0.1255, 0.4318, 0.0935], [-0.3859, -0.1090, -0.1257]],
          [[-0.6560, -0.1389, -0.1010], [-0.0494, -0.5862, -0.2144], [0.1139, -0.5287, -0.3207]],
          [[0.2527, 0.6616, -0.1320], [0.2834, -0.1787, -0.1887], [0.2339, 0.6370, -0.1075]]
        ]
      ]),
      atol: 1.0e-4
    )

    assert_all_close(
      to_channels_first(outputs.latent_dist.var)[[.., 1..3, 1..3, 1..3]],
      Nx.tensor([
        [
          [[0.7926, 0.6405, 0.8108], [0.4721, 0.9543, 0.8660], [0.5069, 0.7749, 0.9574]],
          [[0.4830, 1.2762, 1.1277], [0.9835, 1.1715, 1.5034], [1.2341, 1.0105, 1.2950]],
          [[1.7315, 1.8338, 1.7099], [1.6843, 1.5880, 1.2972], [1.2979, 1.3841, 1.1591]]
        ]
      ]),
      atol: 1.0e-4
    )
  end
end
